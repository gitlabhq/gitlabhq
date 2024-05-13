# frozen_string_literal: true

module Projects
  module ImportExport
    class CreateRelationExportsWorker
      include ApplicationWorker
      include ExceptionBacktrace

      idempotent!
      data_consistency :always
      deduplicate :until_executed
      feature_category :importers
      worker_resource_boundary :cpu
      sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

      # This delay is an arbitrary number to finish the export quicker in case all relations
      # are exported before the first execution of the WaitRelationExportsWorker worker.
      INITIAL_DELAY = 10.seconds

      # rubocop: disable CodeReuse/ActiveRecord
      def perform(user_id, project_id, after_export_strategy = {}, params = {})
        project = Project.find_by_id(project_id)
        return unless project

        params.symbolize_keys!

        project_export_job = project.export_jobs.find_or_create_by!(jid: jid) do |export_job|
          export_job.user_id = user_id
          export_job.exported_by_admin = !!params[:exported_by_admin]
        end
        return if project_export_job.started?

        relation_exports = RelationExport.relation_names_list.map do |relation_name|
          project_export_job.relation_exports.find_or_create_by!(relation: relation_name)
        end

        relation_exports.each do |relation_export|
          RelationExportWorker.with_status.perform_async(relation_export.id, user_id, params)
        end

        project_export_job.start!

        WaitRelationExportsWorker.perform_in(
          INITIAL_DELAY,
          project_export_job.id,
          user_id,
          after_export_strategy
        )
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
