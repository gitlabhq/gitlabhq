class AdminEmailWorker
  include Sidekiq::Worker

  sidekiq_options retry: false # this job auto-repeats via sidekiq-cron

  def perform
    repo_check_failed_count = Project.where(last_repo_check_failed: true).count
    return if repo_check_failed_count.zero?

    RepoCheckMailer.notify(repo_check_failed_count).deliver_now
  end
end
