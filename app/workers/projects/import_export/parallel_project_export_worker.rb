# frozen_string_literal: true

module Projects
  module ImportExport
    class ParallelProjectExportWorker
      include ApplicationWorker
      include ExceptionBacktrace

      idempotent!
      data_consistency :always
      deduplicate :until_executed
      feature_category :importers
      worker_resource_boundary :memory
      urgency :low
      loggable_arguments 1, 2
      sidekiq_options retries: 3, dead: false, status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

      sidekiq_retries_exhausted do |job, exception|
        export_job = ProjectExportJob.find(job['args'].first)

        export_job.fail_op!
        project = export_job.project

        log_payload = {
          message: 'Parallel project export error',
          export_error: job['error_message'],
          project_export_job_id: export_job.id,
          project_name: project.name,
          project_id: project.id
        }
        Gitlab::ExceptionLogFormatter.format!(exception, log_payload)
        Gitlab::Export::Logger.error(log_payload)
      end

      def perform(project_export_job_id, user_id, after_export_strategy = {})
        export_job = ProjectExportJob.find(project_export_job_id)

        return if export_job.finished?

        export_job.update_attribute(:jid, jid)
        current_user = User.find(user_id)
        after_export = build!(after_export_strategy)

        export_service = ::Projects::ImportExport::ParallelExportService.new(export_job, current_user, after_export)
        export_service.execute

        export_job.finish!
      rescue Gitlab::ImportExport::AfterExportStrategyBuilder::StrategyNotFoundError
        export_job.fail_op!
      end

      private

      def build!(after_export_strategy)
        strategy_klass = after_export_strategy&.delete('klass')

        Gitlab::ImportExport::AfterExportStrategyBuilder.build!(strategy_klass, after_export_strategy)
      end
    end
  end
end
