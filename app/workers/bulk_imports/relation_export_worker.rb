# frozen_string_literal: true

module BulkImports
  class RelationExportWorker
    include ApplicationWorker
    include ExceptionBacktrace

    idempotent!
    loggable_arguments 2, 3
    feature_category :importers
    tags :exclude_from_kubernetes
    sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

    def perform(user_id, exportable_id, exportable_class, relation)
      user = User.find(user_id)
      exportable = exportable(exportable_id, exportable_class)

      RelationExportService.new(user, exportable, relation, jid).execute
    end

    private

    def exportable(exportable_id, exportable_class)
      exportable_class.classify.constantize.find(exportable_id)
    end
  end
end
