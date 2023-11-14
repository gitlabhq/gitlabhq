# frozen_string_literal: true

class ScheduleMergeRequestCleanupRefsWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :code_review_workflow
  idempotent!

  def perform
    return if Gitlab::Database.read_only?

    MergeRequest::CleanupSchedule.stuck_retry!
    MergeRequestCleanupRefsWorker.perform_with_capacity
  end
end
