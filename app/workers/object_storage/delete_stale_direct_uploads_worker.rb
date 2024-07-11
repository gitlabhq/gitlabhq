# frozen_string_literal: true

module ObjectStorage
  class DeleteStaleDirectUploadsWorker
    include ApplicationWorker

    data_consistency :sticky
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    # TODO: Determine proper feature category for this, as object storage is a shared feature.
    # For now, only build artifacts use this worker.
    feature_category :job_artifacts
    idempotent!
    deduplicate :until_executed

    def perform
      result = ObjectStorage::DeleteStaleDirectUploadsService.new.execute

      log_extra_metadata_on_done(:total_pending_entries, result[:total_pending_entries])
      log_extra_metadata_on_done(:total_deleted_stale_entries, result[:total_deleted_stale_entries])
      log_extra_metadata_on_done(:execution_timeout, result[:execution_timeout])
    end
  end
end
