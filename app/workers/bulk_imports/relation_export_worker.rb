# frozen_string_literal: true

module BulkImports
  class RelationExportWorker
    include ApplicationWorker
    include ExceptionBacktrace

    idempotent!
    deduplicate :until_executed
    loggable_arguments 2, 3
    data_consistency :always
    feature_category :importers
    sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION
    worker_resource_boundary :memory

    def perform(user_id, portable_id, portable_class, relation, batched = false)
      user = User.find(user_id)
      portable = portable(portable_id, portable_class)
      config = BulkImports::FileTransfer.config_for(portable)

      if Feature.enabled?(:bulk_imports_batched_import_export) &&
          Gitlab::Utils.to_boolean(batched) &&
          config.batchable_relation?(relation)
        BatchedRelationExportService.new(user, portable, relation, jid).execute
      else
        RelationExportService.new(user, portable, relation, jid).execute
      end
    end

    private

    def portable(portable_id, portable_class)
      portable_class.classify.constantize.find(portable_id)
    end
  end
end
