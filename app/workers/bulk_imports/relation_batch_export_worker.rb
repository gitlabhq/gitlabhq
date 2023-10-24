# frozen_string_literal: true

module BulkImports
  class RelationBatchExportWorker
    include ApplicationWorker

    idempotent!
    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency
    feature_category :importers
    sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

    def perform(user_id, batch_id)
      @user = User.find(user_id)
      @batch = BulkImports::ExportBatch.find(batch_id)

      log_extra_metadata_on_done(:relation, @batch.export.relation)
      log_extra_metadata_on_done(:objects_count, @batch.objects_count)

      RelationBatchExportService.new(@user, @batch).execute
    end
  end
end
