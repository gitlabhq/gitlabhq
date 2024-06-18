# frozen_string_literal: true

class ProjectExportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always
  include ExceptionBacktrace

  feature_category :importers
  worker_resource_boundary :memory
  urgency :low
  loggable_arguments 2, 3
  sidekiq_options retry: false, dead: false
  sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

  def perform(current_user_id, project_id, after_export_strategy = {}, params = {})
    current_user = User.find(current_user_id)
    params.symbolize_keys!

    project = Project.find(project_id)
    export_job = project.export_jobs.safe_find_or_create_by(jid: self.jid) do |job|
      job.user = current_user
      job.exported_by_admin = !!params[:exported_by_admin]
    end
    after_export = build!(after_export_strategy)

    export_job&.start

    export_service = ::Projects::ImportExport::ExportService.new(project, current_user, params)
    export_service.execute(after_export)

    log_exporters_duration(export_service)

    export_job&.finish
  rescue ActiveRecord::RecordNotFound => e
    log_failure(project_id, e)
  rescue Gitlab::ImportExport::AfterExportStrategyBuilder::StrategyNotFoundError => e
    log_failure(project_id, e)
    export_job&.finish
  rescue StandardError => e
    log_failure(project_id, e)
    export_job&.fail_op
    raise
  end

  private

  def build!(after_export_strategy)
    strategy_klass = after_export_strategy&.delete('klass')

    Gitlab::ImportExport::AfterExportStrategyBuilder.build!(strategy_klass, after_export_strategy)
  end

  def log_failure(project_id, ex)
    logger.error("Failed to export project #{project_id}: #{ex.message}")
  end

  def log_exporters_duration(export_service)
    export_service.exporters.each do |exporter|
      exporter_key = "#{exporter.class.name.demodulize.underscore}_duration_s".to_sym # e.g. uploads_saver_duration_s
      exporter_duration = exporter.duration_s&.round(6)

      log_extra_metadata_on_done(exporter_key, exporter_duration)
    end
  end
end
