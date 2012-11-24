class ProjectObserver < ActiveRecord::Observer
  def after_save(project)
    # Move repository if namespace changed
    if project.namespace_id_changed? and not project.new_record?
      old_dir = Namespace.find_by_id(project.namespace_id_was).try(:path) || ''
      new_dir = Namespace.find_by_id(project.namespace_id).try(:path) || ''

      Gitlab::ProjectMover.new(project, old_dir, new_dir).execute
    end

    # Update gitolite
    project.update_repository
  end

  def after_destroy(project)
    log_info("Project \"#{project.name}\" was removed")

    project.destroy_repository
  end

  def after_create project
    log_info("#{project.owner.name} created a new project \"#{project.name}\"")
  end

  protected

  def log_info message
    Gitlab::AppLogger.info message
  end
end
