# frozen_string_literal: true

module PersonalAccessTokens
  class ExpiringWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize

    data_consistency :always

    include CronjobQueue

    feature_category :system_access

    MAX_TOKENS = 100

    # For the worker is timing out with a bigger batch size
    # https://gitlab.com/gitlab-org/gitlab/-/issues/432518
    BATCH_SIZE = 100

    def perform(*args)
      # rubocop: disable CodeReuse/ActiveRecord -- We need to specify batch size to avoid timing out of worker
      loop do
        tokens = PersonalAccessToken.expiring_and_not_notified_without_impersonation
          .select(:user_id).limit(BATCH_SIZE).to_a

        break if tokens.empty?

        users = User.with_personal_access_tokens_expiring_soon_and_ids(tokens.pluck(:user_id).uniq)

        users.each do |user|
          with_context(user: user) do
            expiring_user_tokens = user.expiring_soon_and_unnotified_personal_access_tokens

            next if expiring_user_tokens.empty?

            # We never materialise the token instances. We need the names to mention them in the
            # email. Later we trigger an update query on the entire relation, not on individual instances.
            token_names = expiring_user_tokens.limit(MAX_TOKENS).pluck(:name)
            # We're limiting to 100 tokens so we avoid loading too many tokens into memory.
            # At the time of writing this would only affect 69 users on GitLab.com

            # rubocop: enable CodeReuse/ActiveRecord
            if user.project_bot?
              deliver_bot_notifications(token_names, user)
            else
              deliver_user_notifications(token_names, user)
            end

            expiring_user_tokens.update_all(expire_notification_delivered: true)
          end
        end
      end
    end

    private

    def deliver_bot_notifications(token_names, user)
      notification_service.resource_access_tokens_about_to_expire(user, token_names)

      Gitlab::AppLogger.info(
        message: "Notifying Bot User resource owners about expiring tokens",
        class: self.class,
        user_id: user.id
      )
    end

    def deliver_user_notifications(token_names, user)
      notification_service.access_token_about_to_expire(user, token_names)

      Gitlab::AppLogger.info(
        message: "Notifying User about expiring tokens",
        class: self.class,
        user_id: user.id
      )
    end

    def notification_service
      NotificationService.new
    end
    strong_memoize_attr :notification_service
  end
end
