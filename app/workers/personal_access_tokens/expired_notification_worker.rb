# frozen_string_literal: true

module PersonalAccessTokens
  class ExpiredNotificationWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include CronjobQueue

    feature_category :authentication_and_authorization
    tags :exclude_from_kubernetes

    def perform(*args)
      notification_service = NotificationService.new

      User.with_personal_access_tokens_expired_today.find_each do |user|
        with_context(user: user) do
          Gitlab::AppLogger.info "#{self.class}: Notifying User #{user.id} about an expired token"

          notification_service.access_token_expired(user)

          user.personal_access_tokens.without_impersonation.expired_today_and_not_notified.update_all(after_expiry_notification_delivered: true)
        end
      end
    end
  end
end
