# frozen_string_literal: true

class ProjectExportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always
  include ExceptionBacktrace

  feature_category :importers
  worker_resource_boundary :memory
  urgency :throttled
  loggable_arguments 2, 3
  sidekiq_options retry: false, dead: false
  sidekiq_options status_expiration: StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION

  def perform(current_user_id, project_id, after_export_strategy = {}, params = {})
    current_user = User.find(current_user_id)
    project = Project.find(project_id)
    export_job = project.export_jobs.safe_find_or_create_by(jid: self.jid)
    after_export = build!(after_export_strategy)

    export_job&.start

    ::Projects::ImportExport::ExportService.new(project, current_user, params).execute(after_export)

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
end
