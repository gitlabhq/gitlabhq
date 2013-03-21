class ProjectObserver < ActiveRecord::Observer
  def after_create(project)
    GitlabShellWorker.perform_async(
      :add_repository,
      project.path_with_namespace
    )

    log_info("#{project.owner.name} created a new project \"#{project.name_with_namespace}\"")
  end

  def after_update(project)
    project.send_move_instructions if project.namespace_id_changed?
    if project.git_protocol_enabled_changed?
      if project.git_protocol_enabled
        log_info("#{project.owner.name} granted public access via git protocol for project \"#{project.name_with_namespace}\"")
        GitlabShellWorker.perform_async(
          :enable_git_protocol,
          project.path_with_namespace
        )
      else
        log_info("#{project.owner.name} removed public access via git protocol for project \"#{project.name_with_namespace}\"")
        GitlabShellWorker.perform_async(
          :disable_git_protocol,
          project.path_with_namespace
        )
      end
    end
  end

  def after_destroy(project)
    GitlabShellWorker.perform_async(
      :remove_repository,
      project.path_with_namespace
    )

    GitlabShellWorker.perform_async(
      :remove_repository,
      project.path_with_namespace + ".wiki"
    )

    project.satellite.destroy

    log_info("Project \"#{project.name}\" was removed")
  end

  protected

  def log_info message
    Gitlab::AppLogger.info message
  end
end
