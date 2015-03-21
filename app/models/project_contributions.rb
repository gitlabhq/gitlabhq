class ProjectContributions
  attr_reader :project, :user

  def initialize(project, user)
    @project, @user = project, user
  end

  def commits_log
    repository = project.repository

    if !repository.exists? || repository.empty?
      return {}
    end

    Rails.cache.fetch(cache_key) do
      repository.commits_per_day_for_user(user)
    end
  end

  def user_commits_on_date(date)
    repository = @project.repository

    if !repository.exists? || repository.empty?
      return []
    end
    commits = repository.commits_by_user_on_date_log(@user, date)
  end

  def cache_key
    "#{Date.today.to_s}-commits-log-#{project.id}-#{user.email}"
  end
end
