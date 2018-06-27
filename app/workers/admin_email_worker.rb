# frozen_string_literal: true

class AdminEmailWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    send_repository_check_mail if Gitlab::CurrentSettings.repository_checks_enabled
  end

  private

  def send_repository_check_mail
    repository_check_failed_count = Project.where(last_repository_check_failed: true).count
    return if repository_check_failed_count.zero?

    RepositoryCheckMailer.notify(repository_check_failed_count).deliver_now
  end
end
