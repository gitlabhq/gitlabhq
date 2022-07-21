# frozen_string_literal: true

module Projects
  module ImportExport
    class RelationExportWorker
      include ApplicationWorker
      include ExceptionBacktrace

      idempotent!
      data_consistency :always
      deduplicate :until_executed
      feature_category :importers
      sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION
      urgency :low
      worker_resource_boundary :memory

      def perform(project_relation_export_id)
        relation_export = Projects::ImportExport::RelationExport.find(project_relation_export_id)

        if relation_export.queued?
          Projects::ImportExport::RelationExportService.new(relation_export, jid).execute
        end
      end
    end
  end
end
