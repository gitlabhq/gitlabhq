# frozen_string_literal: true

class AdminEmailWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :source_code_management

  def perform
    send_repository_check_mail if Gitlab::CurrentSettings.repository_checks_enabled
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def send_repository_check_mail
    repository_check_failed_count = Project.where(last_repository_check_failed: true).count
    return if repository_check_failed_count == 0

    RepositoryCheckMailer.notify(repository_check_failed_count).deliver_now
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
