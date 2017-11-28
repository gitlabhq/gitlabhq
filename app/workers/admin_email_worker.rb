class AdminEmailWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    repository_check_failed_count = Project.where(last_repository_check_failed: true).count
    return if repository_check_failed_count.zero?

    RepositoryCheckMailer.notify(repository_check_failed_count).deliver_now
  end
end
