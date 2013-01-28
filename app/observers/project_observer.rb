class ProjectObserver < ActiveRecord::Observer
  def after_create(project)
    project.update_repository
  end

  def after_update(project)
    project.send_move_instructions if project.namespace_id_changed?
  end

  def after_destroy(project)
    log_info("Project \"#{project.name}\" was removed")

    project.satellite.destroy
    project.destroy_repository
  end

  def after_create project
    log_info("#{project.owner.name} created a new project \"#{project.name_with_namespace}\"")
  end

  protected

  def log_info message
    Gitlab::AppLogger.info message
  end
end
