# frozen_string_literal: true

class AdminEmailWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :sticky

  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue

  # rubocop:enable Scalability/CronWorkerContext

  feature_category :source_code_management

  def perform
    send_repository_check_mail if Gitlab::CurrentSettings.repository_checks_enabled
  end

  private

  def send_repository_check_mail
    repository_check_failed_count = Project.last_repository_check_failed.count
    return if repository_check_failed_count == 0

    RepositoryCheckMailer.notify(repository_check_failed_count).deliver_now
  end
end
