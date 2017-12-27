class RepositoryImportWorker
  include ApplicationWorker
  include ExceptionBacktrace
  include ProjectStartImport
  include ProjectImportOptions

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

    raise result[:message] if result[:status] == :error

    project.after_import

    # Explicitly enqueue mirror for update so
    # that upstream remote is created and fetched
    project.force_import_job! if project.mirror?
  end

  private

  def start_import(project)
    return true if start(project)

    Rails.logger.info("Project #{project.full_path} was in inconsistent state (#{project.import_status}) while importing.")
    false
  end
end
