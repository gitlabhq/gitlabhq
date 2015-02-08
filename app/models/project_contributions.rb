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

  def cache_key
    "#{Date.today.to_s}-commits-log-#{project.id}-#{user.email}"
  end
end
