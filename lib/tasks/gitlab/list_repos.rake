namespace :gitlab do
  task list_repos: :environment do
    scope = Project
    if ENV['SINCE']
      date = Time.parse(ENV['SINCE'])
      warn "Listing repositories with activity since #{date}"
      project_ids = Project.where(['last_activity_at > ?', date]).pluck(:id)
      scope = scope.where(id: project_ids)
    end
    scope.find_each do |project|
      base = File.join(Gitlab.config.gitlab_shell.repos_path, project.path_with_namespace)
      puts base + '.git'
      puts base + '.wiki.git'
    end
  end
end
