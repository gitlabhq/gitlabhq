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

    if result[:status] == :error
      fail_import(project, result[:message]) if project.gitlab_project_import?

      raise result[:message]
    end

    project.after_import
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
