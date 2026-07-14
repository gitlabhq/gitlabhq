# frozen_string_literal: true

module MergeRequests
  class UnstickLockedMergeRequestsService
    include BaseServiceUtility

    def execute
      Gitlab::MergeRequests::LockedSet.each_batch(100) do |batch|
        merge_requests = merge_requests_batch(batch)
        merge_requests_with_merge_jid = merge_requests.select { |mr| mr.locked? && mr.merge_jid.present? }
        merge_requests_without_merge_jid = merge_requests.select { |mr| mr.locked? && mr.merge_jid.blank? }
        unlocked_merge_requests = merge_requests.select { |mr| !mr.locked? }

        attempt_to_unstick_mrs_with_merge_jid(merge_requests_with_merge_jid)
        attempt_to_unstick_mrs_without_merge_jid(merge_requests_without_merge_jid)

        unlocked_merge_requests.each do |merge_request|
          log_info(
            message: 'Removed already-unlocked merge request from locked set',
            merge_request_id: merge_request.id,
            merge_jid: merge_request.merge_jid,
            state: merge_request.state
          )
        end
        remove_from_locked_set(unlocked_merge_requests)
      end
    end

    private

    # This method is overridden in EE to extend its functionality like preloading
    # associations.
    def merge_requests_batch(ids)
      MergeRequest.id_in(ids)
    end

    def attempt_to_unstick_mrs_with_merge_jid(merge_requests)
      return if merge_requests.empty?

      jids = merge_requests.map(&:merge_jid)

      # Find the jobs that aren't currently running or that exceeded the threshold.
      completed_jids = Gitlab::SidekiqStatus.completed_jids(jids).to_set

      return if completed_jids.empty?

      completed_mrs = merge_requests.select { |mr| completed_jids.include?(mr.merge_jid) }

      mrs_to_mark_as_merged, mrs_to_unlock = completed_mrs.partition do |mr|
        mr.merge_commit_sha.present?
      end

      mark_merge_requests_as_merged(
        mrs_to_mark_as_merged.map { |mr| { id: mr.id, merge_jid: mr.merge_jid } }
      )
      unlock_merge_requests(mrs_to_unlock)
    end

    def attempt_to_unstick_mrs_without_merge_jid(merge_requests)
      return if merge_requests.empty?

      merge_requests_to_reopen = []
      merge_request_ids_to_mark_as_merged = []

      merge_requests.each do |merge_request|
        next unless should_unstick?(merge_request)

        # Reset merge request record to ensure we get updated record state before
        # we check attributes. It is possible that after we queried the MRs, they
        # got merged or unlocked and marked as such successfully. If so, skip MR.
        next unless merge_request.reset.locked?

        # Set MR to be marked as merged if one of the following is true:
        # - it already has merged_commit_sha in the DB
        # - it already has merge_commit_sha in the DB
        # - it has no diffs where source and target branches are compared
        #
        # This means the MR changes were already merged.
        #
        # We read the value of the column from the DB instead of MergeRequest#merged_commit_sha
        # as that method can return nil when MR is still not merged.
        #
        # We also check the `merge_commit_sha` if present as there are older MRs that do not have
        # `merged_commit_sha` set on merge.
        #
        # When both attributes aren't set, we check if the MR still has diffs to see
        # if the MR changes are already merged or not.
        if merge_request.read_attribute(:merged_commit_sha).present? ||
            merge_request.merge_commit_sha.present? ||
            (merge_request.source_and_target_branches_exist? && !merge_request.has_diffs?)
          merge_request_ids_to_mark_as_merged << merge_request.id
        else
          # Set MR to be unlocked since it's stuck and maybe not merged yet.
          merge_requests_to_reopen << merge_request
        end
      end

      mark_merge_requests_as_merged(
        merge_request_ids_to_mark_as_merged.map { |id| { id: id, merge_jid: nil } }
      )
      unlock_merge_requests(merge_requests_to_reopen)
    end

    # Check if MR is still in the process of merging so we don't interrupt the process.
    # MergeRequest::MergeService will acquire a lease when merging and keep it for
    # 15 minutes so we can check if the lease still exists and we can consider
    # the MR as still merging.
    def should_unstick?(merge_request)
      !merge_request.merge_exclusive_lease.exists?
    end

    # Accepts an array of `{ id:, merge_jid: }` hashes so callers can supply
    # the merge_jid (which may have been cleared in-memory by the time we'd
    # otherwise re-read it) without forcing us to re-query the relation.
    def mark_merge_requests_as_merged(merge_request_entries)
      return if merge_request_entries.empty?

      ids = merge_request_entries.map { |entry| entry[:id] } # rubocop:disable Rails/Pluck -- Array of Hash, not AR relation
      MergeRequest.id_in(ids).update_all(state_id: MergeRequest.available_states[:merged])
      Gitlab::MergeRequests::LockedSet.remove(ids)

      merge_request_entries.each do |entry|
        log_info(
          message: 'Marked locked merge request as merged',
          merge_request_id: entry[:id],
          merge_jid: entry[:merge_jid]
        )
      end
    end

    # Do not reopen merge requests using direct queries.
    # We rely on state machine callbacks to update head_pipeline_id
    def unlock_merge_requests(merge_requests)
      merge_requests.each do |merge_request|
        # Capture merge_jid before unlock_mr, which clears it via the state
        # transition callback regardless of whether the save succeeds.
        merge_jid = merge_request.merge_jid

        if merge_request.unlock_mr
          merge_request.remove_from_locked_set

          log_info(
            message: 'Reopened locked merge request',
            merge_request_id: merge_request.id,
            merge_jid: merge_jid
          )
          next
        end

        # Some MRs can never be reopened because doing so now fails a structural
        # validation (e.g. a newer opened MR occupies the same source branch, or
        # the fork relationship is gone). Without recovery they stay locked
        # forever (#600038), so we force them closed instead of only logging.
        if merge_request.force_unlock_and_close
          merge_request.remove_from_locked_set

          log_info(
            message: 'Force-closed stuck locked merge request',
            merge_request_id: merge_request.id,
            merge_jid: merge_jid
          )
          next
        end

        log_error(
          message: 'Failed to unlock locked merge request',
          merge_request_id: merge_request.id,
          merge_jid: merge_jid,
          errors: merge_request.errors.full_messages
        )
      end
    end

    def remove_from_locked_set(merge_requests)
      return if merge_requests.empty?

      Gitlab::MergeRequests::LockedSet.remove(merge_requests.map(&:id))
    end

    def log_info(**payload)
      Gitlab::AppJsonLogger.info(**payload, class: self.class.name)
    end

    def log_error(**payload)
      Gitlab::AppJsonLogger.error(**payload, class: self.class.name)
    end
  end
end

MergeRequests::UnstickLockedMergeRequestsService.prepend_mod
