class RepositoryImportWorker
  ImportError = Class.new(StandardError)

  include Sidekiq::Worker
  include DedicatedSidekiqQueue
  include ExceptionBacktrace
  include ProjectStartImport

  sidekiq_options status_expiration: StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION

  def perform(project_id)
    project = Project.find(project_id)

    return unless start_import(project)

    Gitlab::Metrics.add_event(:import_repository,
                              import_url: project.import_url,
                              path: project.full_path)

    service = Projects::ImportService.new(project, project.creator)
    result = service.execute

    # Some importers may perform their work asynchronously. In this case it's up
    # to those importers to mark the import process as complete.
    return if service.async?

    raise ImportError, result[:message] if result[:status] == :error

    project.after_import
  rescue ImportError => ex
    fail_import(project, ex.message)
    raise
  rescue => ex
    return unless project

    fail_import(project, ex.message)
    raise ImportError, "#{ex.class} #{ex.message}"
  end

  private

  def start_import(project)
    return true if start(project)

    Rails.logger.info("Project #{project.full_path} was in inconsistent state (#{project.import_status}) while importing.")
    false
  end

  def fail_import(project, message)
    project.mark_import_as_failed(message)
  end
end
