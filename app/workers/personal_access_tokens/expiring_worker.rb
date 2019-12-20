# frozen_string_literal: true

module PersonalAccessTokens
  class ExpiringWorker
    include ApplicationWorker
    include CronjobQueue

    feature_category :authentication_and_authorization

    def perform(*args)
      notification_service = NotificationService.new
      limit_date = PersonalAccessToken::DAYS_TO_EXPIRE.days.from_now.to_date

      User.with_expiring_and_not_notified_personal_access_tokens(limit_date).find_each do |user|
        notification_service.access_token_about_to_expire(user)

        Rails.logger.info "#{self.class}: Notifying User #{user.id} about expiring tokens" # rubocop:disable Gitlab/RailsLogger

        user.personal_access_tokens.expiring_and_not_notified(limit_date).update_all(expire_notification_delivered: true)
      end
    end
  end
end
