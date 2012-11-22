class ProjectObserver < ActiveRecord::Observer
  def before_save(project)
    # Move repository if namespace changed
    if project.namespace_id_changed?
      move_project(project)
    end
  end

  def after_save(project)
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

  def move_project(project)
    old_dir = Namespace.find_by_id(project.namespace_id_was).try(:code) || ''
    new_dir = Namespace.find_by_id(project.namespace_id).try(:code) || ''

    # Create new dir if missing
    new_dir_path = File.join(Gitlab.config.git_base_path, new_dir)
    Dir.mkdir(new_dir_path) unless File.exists?(new_dir_path)

    old_path = File.join(Gitlab.config.git_base_path, old_dir, "#{project.path}.git")
    new_path = File.join(new_dir_path, "#{project.path}.git")

    `mv #{old_path} #{new_path}`

    log_info "Project #{project.name} was moved from #{old_path} to #{new_path}"
  end
end
