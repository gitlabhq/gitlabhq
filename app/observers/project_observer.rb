class ProjectObserver < BaseObserver
  def after_create(project)
    project.update_column(:last_activity_at, project.created_at)

    return true if project.forked?

    if project.import?
      RepositoryImportWorker.perform_in(5.seconds, project.id)
    else
      GitlabShellWorker.perform_async(
        :add_repository,
        project.path_with_namespace
      )

      log_info("#{project.owner.name} created a new project \"#{project.name_with_namespace}\"")
    end
  end

  def after_update(project)
    project.send_move_instructions if project.namespace_id_changed?
    project.rename_repo if project.path_changed?

    GitlabShellWorker.perform_async(
      :update_repository_head,
      project.path_with_namespace,
      project.default_branch
    ) if project.default_branch_changed?
    
    repo_dir = Gitlab.config.gitlab_shell.repos_path.to_s
    default_notify_file = File.join(repo_dir,"notify.yml")
    project_repo_dir = File.join(repo_dir,"#{project.path_with_namespace}.git")
    repo_notify_config_file = File.join(project_repo_dir,"notify.yml")
    user_emails = project.users.map(&:email).join(',')
    File.open(repo_notify_config_file,'w') do |out|
       out<<File.open(default_notify_file).read.gsub(/^mailinglist:/,"mailinglist: #{user_emails}")
    end
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
