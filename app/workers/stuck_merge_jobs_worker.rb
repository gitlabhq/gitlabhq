# frozen_string_literal: true

class StuckMergeJobsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :code_review_workflow

  def self.logger
    Gitlab::AppLogger
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    if MergeRequest.use_locked_set?
      MergeRequests::UnstickLockedMergeRequestsService.new.execute
    else
      stuck_merge_requests.find_in_batches(batch_size: 100) do |group|
        # The logic in this block also exists in `MergeRequests::UnstickLockedMergeRequestsService`
        # since that is intended to replace this once the feature flag is fully rolled out.
        #
        # Any changes that needs to be applied here should be applied to the service as well.
        jids = group.map(&:merge_jid)

        # Find the jobs that aren't currently running or that exceeded the threshold.
        completed_jids = Gitlab::SidekiqStatus.completed_jids(jids)

        if completed_jids.any?
          completed_ids = group.select { |merge_request| completed_jids.include?(merge_request.merge_jid) }.map(&:id)

          apply_current_state!(completed_jids, completed_ids)
        end
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def apply_current_state!(completed_jids, completed_ids)
    merge_requests = MergeRequest.where(id: completed_ids)

    merge_requests.where.not(merge_commit_sha: nil).update_all(state_id: MergeRequest.available_states[:merged])

    merge_requests_to_reopen = merge_requests.where(merge_commit_sha: nil)

    # Do not reopen merge requests using direct queries.
    # We rely on state machine callbacks to update head_pipeline_id
    errors = Hash.new { |h, k| h[k] = [] }

    merge_requests_to_reopen.each do |mr|
      mjid = mr.merge_jid

      next if mr.unlock_mr

      mr.errors.full_messages.each do |msg|
        errors[msg] << ["#{mjid}|#{mr.id}"]
      end
    end

    self.class.logger.info("Updated state of locked merge jobs. JIDs: #{completed_jids.join(', ')}")
    built_errors = errors.map { |k, v| "#{k} - IDS: #{v.join(',')}\n" }.join
    self.class.logger.info("Errors:\n#{built_errors}")
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def stuck_merge_requests
    MergeRequest.select('id, merge_jid').with_state(:locked).where.not(merge_jid: nil).reorder(nil)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
