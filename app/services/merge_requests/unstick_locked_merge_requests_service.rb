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
        remove_from_locked_set(unlocked_merge_requests)
      end
    end

    private

    # This method is overridden in EE to extend its functionality like preloading
    # associations.
    def merge_requests_batch(ids)
      MergeRequest.id_in(ids)
    end

    # The logic in this method is the same as in `StuckMergeJobsWorker`. This service
    # is intended to replace the logic in that worker once feature flag is fully rolled out.
    #
    # Any changes that needs to be applied here should be applied to the worker as well.
    #
    # rubocop: disable CodeReuse/ActiveRecord -- TODO: Introduce new AR scopes for queries used in this method
    def attempt_to_unstick_mrs_with_merge_jid(merge_requests)
      return if merge_requests.empty?

      jids = merge_requests.map(&:merge_jid)

      # Find the jobs that aren't currently running or that exceeded the threshold.
      completed_jids = Gitlab::SidekiqStatus.completed_jids(jids)

      return if completed_jids.empty?

      completed_ids = merge_requests.select do |merge_request|
        completed_jids.include?(merge_request.merge_jid)
      end.map(&:id)

      completed_merge_requests = MergeRequest.id_in(completed_ids)

      mark_merge_requests_as_merged(completed_merge_requests.where.not(merge_commit_sha: nil))
      unlock_merge_requests(completed_merge_requests.where(merge_commit_sha: nil))

      log_info("Updated state of locked merge jobs. JIDs: #{completed_jids.join(', ')}")
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def attempt_to_unstick_mrs_without_merge_jid(merge_requests)
      return if merge_requests.empty?

      merge_requests_to_reopen = []
      merge_request_ids_to_mark_as_merged = []

      merge_requests.each do |merge_request|
        next unless Feature.enabled?(:unstick_locked_mrs_without_merge_jid, merge_request.project)
        next unless should_unstick?(merge_request)

        # Reset merge request record to ensure we get updated record state before
        # we check attributes. It is possible that after we queried the MRs, they
        # got merged or unlocked and marked as such successfully. If so, skip MR.
        next unless merge_request.reset.locked?

        # Set MR to be marked as merged if one of the following is true:
        # - it already has merged_commit_sha in the DB
        # - it alreeady has merge_commit_sha in the DB
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

      mark_merge_requests_as_merged(MergeRequest.id_in(merge_request_ids_to_mark_as_merged))
      unlock_merge_requests(merge_requests_to_reopen)

      updated_mr_ids = merge_request_ids_to_mark_as_merged | merge_requests_to_reopen.map(&:id)
      log_info("Updated state of locked MRs without JIDs. IDs: #{updated_mr_ids.join(', ')}")
    end

    # Check if MR is still in the process of merging so we don't interrupt the process.
    # MergeRequest::MergeService will acquire a lease when merging and keep it for
    # 15 minutes so we can check if the lease still exists and we can consider
    # the MR as still merging.
    def should_unstick?(merge_request)
      !merge_request.merge_exclusive_lease.exists?
    end

    def mark_merge_requests_as_merged(merge_requests)
      return if merge_requests.empty?

      merge_requests.update_all(state_id: MergeRequest.available_states[:merged])
      remove_from_locked_set(merge_requests)
    end

    # Do not reopen merge requests using direct queries.
    # We rely on state machine callbacks to update head_pipeline_id
    def unlock_merge_requests(merge_requests)
      errors = Hash.new { |h, k| h[k] = [] }

      merge_requests.each do |mr|
        mjid = mr.merge_jid

        if mr.unlock_mr
          mr.remove_from_locked_set
          next
        end

        mr.errors.full_messages.each do |msg|
          errors[msg] << if mjid.present?
                           ["#{mjid}|#{mr.id}"]
                         else
                           [mr.id]
                         end
        end
      end

      built_errors = errors.map { |k, v| "#{k} - IDS: #{v.join(',')}\n" }.join
      log_info("Errors:\n#{built_errors}")
    end

    def remove_from_locked_set(merge_requests)
      return if merge_requests.empty?

      Gitlab::MergeRequests::LockedSet.remove(merge_requests.map(&:id))
    end
  end
end

MergeRequests::UnstickLockedMergeRequestsService.prepend_mod
