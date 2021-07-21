# frozen_string_literal: true

module PersonalAccessTokens
  class ExpiringWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include CronjobQueue

    feature_category :authentication_and_authorization

    MAX_TOKENS = 100

    def perform(*args)
      notification_service = NotificationService.new
      limit_date = PersonalAccessToken::DAYS_TO_EXPIRE.days.from_now.to_date

      User.with_expiring_and_not_notified_personal_access_tokens(limit_date).find_each do |user|
        with_context(user: user) do
          expiring_user_tokens = user.personal_access_tokens.without_impersonation.expiring_and_not_notified(limit_date)

          # rubocop: disable CodeReuse/ActiveRecord
          # We never materialise the token instances. We need the names to mention them in the
          # email. Later we trigger an update query on the entire relation, not on individual instances.
          token_names = expiring_user_tokens.limit(MAX_TOKENS).pluck(:name)
          # We're limiting to 100 tokens so we avoid loading too many tokens into memory.
          # At the time of writing this would only affect 69 users on GitLab.com

          # rubocop: enable CodeReuse/ActiveRecord

          notification_service.access_token_about_to_expire(user, token_names)

          Gitlab::AppLogger.info "#{self.class}: Notifying User #{user.id} about expiring tokens"

          expiring_user_tokens.each_batch do |expiring_tokens|
            expiring_tokens.update_all(expire_notification_delivered: true)
          end
        end
      end
    end
  end
end
