# frozen_string_literal: true

module BulkImports
  class RelationBatchExportWorker
    include ApplicationWorker

    idempotent!
    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency
    feature_category :importers
    sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

    def perform(user_id, batch_id)
      RelationBatchExportService.new(user_id, batch_id).execute
    end
  end
end
