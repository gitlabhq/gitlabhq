# frozen_string_literal: true

module PersonalAccessTokens
  class ExpiredNotificationWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    include CronjobQueue

    feature_category :system_access

    MAX_TOKENS = 100

    def perform(*args)
      notification_service = NotificationService.new

      User.with_personal_access_tokens_expired_today.find_each do |user|
        with_context(user: user) do
          expiring_user_tokens = user.personal_access_tokens.without_impersonation.expired_today_and_not_notified

          # rubocop: disable CodeReuse/ActiveRecord
          # We never materialise the token instances. We need the names to mention them in the
          # email. Later we trigger an update query on the entire relation, not on individual instances.
          token_names = expiring_user_tokens.limit(MAX_TOKENS).pluck(:name)
          # rubocop: enable CodeReuse/ActiveRecord

          notification_service.access_token_expired(user, token_names)

          Gitlab::AppLogger.info "#{self.class}: Notifying User #{user.id} about expired tokens"

          expiring_user_tokens.each_batch do |expiring_tokens|
            expiring_tokens.update_all(after_expiry_notification_delivered: true)
          end
        end
      end
    end
  end
end
