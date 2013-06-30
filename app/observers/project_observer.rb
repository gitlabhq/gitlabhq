class ProjectObserver < BaseObserver
  def after_create(project)
    return true if project.forked? || project.imported?

    GitlabShellWorker.perform_async(
      :add_repository,
      project.path_with_namespace
    )

    log_info("#{project.owner.name} created a new project \"#{project.name_with_namespace}\"")
  end

  def after_update(project)
    project.send_move_instructions if project.namespace_id_changed?
    project.rename_repo if project.path_changed?
  end

  def before_destroy(project)
    project.repository.expire_cache unless project.empty_repo?
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
end
