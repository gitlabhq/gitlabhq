# frozen_string_literal: true

class ScheduleMergeRequestCleanupRefsWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :source_code_management
  idempotent!

  # Based on existing data, MergeRequestCleanupRefsWorker can run 3 jobs per
  # second. This means that 180 jobs can be performed but since there are some
  # spikes from time time, it's better to give it some allowance.
  LIMIT = 180
  DELAY = 10.seconds
  BATCH_SIZE = 30

  def perform
    return if Gitlab::Database.read_only?

    ids = MergeRequest::CleanupSchedule.scheduled_merge_request_ids(LIMIT).map { |id| [id] }

    MergeRequestCleanupRefsWorker.bulk_perform_in(DELAY, ids, batch_size: BATCH_SIZE) # rubocop:disable Scalability/BulkPerformWithContext

    log_extra_metadata_on_done(:merge_requests_count, ids.size)
  end
end
