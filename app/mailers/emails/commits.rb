module Emails
  module Commits
    def receive_commit_email(project, author_id, data)
      repo_dir = Gitlab.config.gitlab_shell.repos_path.to_s
      project_repo_dir = File.join(repo_dir,"#{project.path_with_namespace}.git")
      repo_notify_config_file = File.join(project_repo_dir,"notify.yml")
      
      result = `cd #{project_repo_dir} && echo #{data[:before]} #{data[:after]} #{data[:ref]} | git-commit-notifier #{repo_notify_config_file}`
      #Gitlab::AppLogger.info result
    end
  end
end
