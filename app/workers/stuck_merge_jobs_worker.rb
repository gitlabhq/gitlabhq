# frozen_string_literal: true

class StuckMergeJobsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :code_review

  def self.logger
    Gitlab::AppLogger
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    stuck_merge_requests.find_in_batches(batch_size: 100) do |group|
      jids = group.map(&:merge_jid)

      # Find the jobs that aren't currently running or that exceeded the threshold.
      completed_jids = Gitlab::SidekiqStatus.completed_jids(jids)

      if completed_jids.any?
        completed_ids = group.select { |merge_request| completed_jids.include?(merge_request.merge_jid) }.map(&:id)

        apply_current_state!(completed_jids, completed_ids)
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
    merge_requests_to_reopen.each(&:unlock_mr)

    self.class.logger.info("Updated state of locked merge jobs. JIDs: #{completed_jids.join(', ')}")
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def stuck_merge_requests
    MergeRequest.select('id, merge_jid').with_state(:locked).where.not(merge_jid: nil).reorder(nil)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
