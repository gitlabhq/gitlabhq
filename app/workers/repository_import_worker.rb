class RepositoryImportWorker
  ImportError = Class.new(StandardError)

  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  sidekiq_options status_expiration: StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION

  def perform(project_id)
    project = Project.find(project_id)

    return unless start_import(project)

    Gitlab::Metrics.add_event(:import_repository,
                              import_url: project.import_url,
                              path: project.full_path)

    result = Projects::ImportService.new(project, project.creator).execute
    raise ImportError, result[:message] if result[:status] == :error

    project.repository.after_import
    project.import_finish

    # Explicitly enqueue mirror for update so
    # that upstream remote is created and fetched
    project.force_import_job! if project.mirror?
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
    return true if project.import_start

    Rails.logger.info("Project #{project.full_path} was in inconsistent state (#{project.import_status}) while importing.")
    false
  end

  def fail_import(project, message)
    project.mark_import_as_failed(message)
  end
end
