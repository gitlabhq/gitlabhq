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
      sidekiq_options dead: false, status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION, retry: 6
      urgency :low
      worker_resource_boundary :memory

      sidekiq_retries_exhausted do |job, exception|
        relation_export = Projects::ImportExport::RelationExport.find(job['args'].first)
        project_export_job = relation_export.project_export_job
        project = project_export_job.project

        relation_export.mark_as_failed(job['error_message'])

        log_payload = {
          message: 'Project relation export failed',
          export_error: job['error_message'],
          relation: relation_export.relation,
          project_export_job_id: project_export_job.id,
          project_name: project.name,
          project_id: project.id
        }
        Gitlab::ExceptionLogFormatter.format!(exception, log_payload)
        Gitlab::Export::Logger.error(log_payload)
      end

      def perform(project_relation_export_id, user_id, params = {})
        user = User.find(user_id)
        params.symbolize_keys!
        relation_export = Projects::ImportExport::RelationExport.find(project_relation_export_id)

        log_extra_metadata_on_done(:relation, relation_export.relation)

        relation_export.retry! if relation_export.started?

        if relation_export.queued?
          Projects::ImportExport::RelationExportService.new(relation_export, user, jid, params).execute
        end
      end
    end
  end
end
