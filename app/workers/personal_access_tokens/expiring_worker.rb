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
      process_user_tokens
      process_project_bot_tokens
    end

    private

    def process_user_tokens
      # rubocop: disable CodeReuse/ActiveRecord -- We need to specify batch size to avoid timing out of worker
      loop do
        tokens = PersonalAccessToken
                   .expiring_and_not_notified_without_impersonation
                   .owner_is_human
                   .select(:user_id)
                   .limit(BATCH_SIZE)
                   .load

        break if tokens.empty?

        users = User.id_in(tokens.pluck(:user_id).uniq).with_personal_access_tokens_expiring_soon

        users.each do |user|
          with_context(user: user) do
            expiring_user_tokens = user.expiring_soon_and_unnotified_personal_access_tokens

            next if expiring_user_tokens.empty?

            # We never materialise the token instances. We need the names to mention them in the
            # email. Later we trigger an update query on the entire relation, not on individual instances.
            token_names = expiring_user_tokens.limit(MAX_TOKENS).pluck(:name)
            # We're limiting to 100 tokens so we avoid loading too many tokens into memory.
            # At the time of writing this would only affect 69 users on GitLab.com

            deliver_user_notifications(user, token_names)

            expiring_user_tokens.update_all(expire_notification_delivered: true)
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    def process_project_bot_tokens
      # rubocop: disable CodeReuse/ActiveRecord -- We need to specify batch size to avoid timing out of worker
      notifications_delivered = 0
      project_bot_ids_without_resource = []
      project_bot_ids_with_failed_delivery = []
      loop do
        tokens = PersonalAccessToken
                   .where.not(user_id: project_bot_ids_without_resource | project_bot_ids_with_failed_delivery)
                   .expiring_and_not_notified_without_impersonation
                   .project_access_token
                   .select(:id, :user_id)
                   .limit(BATCH_SIZE)
                   .load

        break if tokens.empty?

        bot_users = User.id_in(tokens.pluck(:user_id).uniq).with_personal_access_tokens_and_resources

        bot_users.each do |project_bot|
          if project_bot.resource_bot_resource.nil?
            project_bot_ids_without_resource << project_bot.id

            next
          end

          begin
            with_context(user: project_bot) do
              # project bot does not have more than 1 token
              expiring_user_token = project_bot.personal_access_tokens.first

              execute_web_hooks(project_bot, expiring_user_token)
              deliver_bot_notifications(project_bot, expiring_user_token.name)
            end
          rescue StandardError => e
            project_bot_ids_with_failed_delivery << project_bot.id

            log_exception(e, project_bot)
          end
        end

        tokens_with_delivered_notifications =
          tokens
            .where.not(user_id: project_bot_ids_without_resource | project_bot_ids_with_failed_delivery)
        tokens_with_delivered_notifications.update_all(expire_notification_delivered: true)

        notifications_delivered += tokens_with_delivered_notifications.count
      end

      log_extra_metadata_on_done(
        :total_notification_delivered_for_resource_access_tokens, notifications_delivered)
      log_extra_metadata_on_done(
        :total_resource_bot_without_membership, project_bot_ids_without_resource.count)
      log_extra_metadata_on_done(
        :total_failed_notifications_for_resource_bots, project_bot_ids_with_failed_delivery.count)

      # rubocop: enable CodeReuse/ActiveRecord
    end

    def deliver_bot_notifications(bot_user, token_name)
      notification_service.bot_resource_access_token_about_to_expire(bot_user, token_name)
    end

    def deliver_user_notifications(user, token_names)
      notification_service.access_token_about_to_expire(user, token_names)
      log_info("Notifying User about expiring tokens", user)
    end

    def log_info(message_text, user)
      Gitlab::AppLogger.info(
        message: message_text,
        class: self.class,
        user_id: user.id
      )
    end

    def log_exception(ex, user)
      Gitlab::AppLogger.error(
        message: 'Failed to send notification about expiring resource access tokens',
        'exception.message': ex.message,
        'exception.class': ex.class.name,
        class: self.class,
        user_id: user.id
      )
    end

    def execute_web_hooks(bot_user, token)
      resource = bot_user.resource_bot_resource

      return unless resource
      return if resource.is_a?(Project) && !resource.has_active_hooks?(:resource_access_token_hooks)

      hook_data = Gitlab::DataBuilder::ResourceAccessToken.build(token, :expiring, resource)
      resource.execute_hooks(hook_data, :resource_access_token_hooks)
    end

    def notification_service
      NotificationService.new
    end
    strong_memoize_attr :notification_service
  end
end
