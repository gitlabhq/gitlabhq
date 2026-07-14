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

    # rubocop: disable CodeReuse/ActiveRecord -- simple system-context lookup, not worth extracting to a finder
    recipients = User.admins.active.pluck(:email)
    # rubocop: enable CodeReuse/ActiveRecord

    recipients.each do |recipient|
      RepositoryCheckMailer.notify(repository_check_failed_count, recipient).deliver_now

    # These are permanent recipient errors and won't be corrected even if Sidekiq retries
    rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
      logger.info(
        structured_payload(message: 'Failed to send repository check notification', recipient: recipient,
          error_message: e.message)
      )
    end
  end
end
