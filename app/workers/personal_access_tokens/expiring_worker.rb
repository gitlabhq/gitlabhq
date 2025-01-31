# frozen_string_literal: true

module PersonalAccessTokens
  class ExpiringWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize

    data_consistency :always

    include CronjobQueue

    feature_category :system_access

    MAX_TOKENS = 100
    MAX_RUNTIME = 3.minutes
    REQUEUE_DELAY = 2.minutes

    # For the worker is timing out with a bigger batch size
    # https://gitlab.com/gitlab-org/gitlab/-/issues/432518
    BATCH_SIZE = 100

    # allows easier stubbing in specs
    def self.batch_size
      BATCH_SIZE
    end

    def perform(*args)
      @runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)
      notification_intervals.each do |interval|
        process_user_tokens(interval)
        break if over_time?

        process_project_bot_tokens(interval)
        break if over_time?
      end

      self.class.perform_in(REQUEUE_DELAY, *args) if over_time?
    end

    private

    attr_reader :runtime_limiter

    delegate :over_time?, to: :runtime_limiter

    def notification_intervals
      PersonalAccessToken::NOTIFICATION_INTERVALS.keys
    end

    def process_user_tokens(interval = :seven_days)
      min_expires_at = nil

      # rubocop: disable CodeReuse/ActiveRecord -- We need to specify batch size to avoid timing out of worker
      loop do
        tokens = PersonalAccessToken
                   .scope_for_notification_interval(interval, min_expires_at: min_expires_at)
                   .owner_is_human
                   .select(:user_id, :expires_at)
                   .order(expires_at: :asc)
                   .limit(self.class.batch_size)
                   .load

        break if tokens.empty?

        users = User.id_in(tokens.pluck(:user_id).uniq).with_personal_access_tokens_expiring_soon

        users.each do |user|
          with_context(user: user) do
            expiring_user_tokens = PersonalAccessToken.scope_for_notification_interval(interval,
              min_expires_at: min_expires_at).for_user(user)

            # We never materialise the token instances. We need the names to mention them in the
            # email. Later we trigger an update query on the entire relation, not on individual instances.
            token_names = expiring_user_tokens.limit(MAX_TOKENS).pluck(:name)
            # We're limiting to 100 tokens so we avoid loading too many tokens into memory.
            # At the time of writing this would only affect 69 users on GitLab.com

            next if token_names.empty?

            interval_days = PersonalAccessToken.notification_interval(interval)
            deliver_user_notifications(user, token_names, days_to_expire: interval_days)

            # we are in the process of deprecating expire_notification_delivered column
            # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166683
            notification_updates = { "#{interval}_notification_sent_at" => Time.current }
            notification_updates[:expire_notification_delivered] = true if interval == :seven_days
            expiring_user_tokens.update_all(notification_updates)
          end
        end

        # manually adjust query interval in case indexes don't update between loops
        min_expires_at = tokens.last&.expires_at
        return if over_time?
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    # this code is quite messy, and should be refactored along with the split out
    # https://gitlab.com/gitlab-org/gitlab/-/issues/495766
    #
    # rubocop: disable CodeReuse/ActiveRecord -- We need to specify batch size to avoid timing out of worker
    def process_project_bot_tokens(interval = :seven_days)
      notifications_delivered = 0
      project_bot_ids_without_resource = []
      project_bot_ids_with_failed_delivery = []
      min_expires_at = nil
      interval_field = "#{interval}_notification_sent_at"
      bot_user_notified_ids = []

      loop do
        exclude_user_ids = project_bot_ids_without_resource | project_bot_ids_with_failed_delivery
        tokens = fetch_bot_tokens(interval, min_expires_at, exclude_user_ids)
        break if tokens.empty?

        token_ids = tokens.pluck(:id)
        bot_user_ids = tokens.pluck(:user_id).uniq

        bot_users = User.id_in(bot_user_ids).with_personal_access_tokens_and_resources

        bot_users.each do |project_bot|
          if project_bot.resource_bot_resource.nil?
            project_bot_ids_without_resource << project_bot.id

            next
          end

          begin
            with_context(user: project_bot) do
              # project bot does not have more than 1 token
              expiring_user_token = project_bot.personal_access_tokens.first

              # webhooks do not include information about when the token expires, so
              # only trigger on seven_days interval to avoid changing existing behavior
              execute_web_hooks(project_bot, expiring_user_token) if interval == :seven_days

              interval_days = PersonalAccessToken.notification_interval(interval)
              deliver_bot_notifications(project_bot, expiring_user_token.name, days_to_expire: interval_days)
              bot_user_notified_ids << project_bot.id
            end
          rescue StandardError => e
            project_bot_ids_with_failed_delivery << project_bot.id

            log_exception(e, project_bot)
          end
        end

        tokens_with_delivered_notifications =
          PersonalAccessToken
            .where(id: token_ids)
            .where.not(user_id: project_bot_ids_without_resource | project_bot_ids_with_failed_delivery)

        # we are in the process of deprecating expire_notification_delivered column
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166683
        notification_updates = { interval_field => Time.current }
        notification_updates[:expire_notification_delivered] = true if interval == :seven_days
        tokens_with_delivered_notifications.update_all(notification_updates)

        notifications_delivered += tokens_with_delivered_notifications.count

        # manually adjust query interval in case indexes don't update between loops
        min_expires_at = tokens.last&.expires_at
        break if over_time?
      end

      log_extra_metadata_on_done(
        :total_notification_delivered_for_resource_access_tokens, notifications_delivered)
      log_extra_metadata_on_done(
        :total_resource_bot_without_membership, project_bot_ids_without_resource.count)
      log_extra_metadata_on_done(
        :total_failed_notifications_for_resource_bots, project_bot_ids_with_failed_delivery.count)
    end

    def fetch_bot_tokens(interval, min_expires_at = nil, exclude_user_ids = [])
      PersonalAccessToken
        .where.not(user_id: exclude_user_ids)
        .scope_for_notification_interval(interval, min_expires_at: min_expires_at)
        .project_access_token
        .select(:id, :user_id, :expires_at)
        .limit(self.class.batch_size)
        .order(expires_at: :asc)
        .load
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def deliver_bot_notifications(bot_user, token_name, days_to_expire: 7)
      notification_service.bot_resource_access_token_about_to_expire(
        bot_user,
        token_name,
        days_to_expire: days_to_expire
      )
    end

    def deliver_user_notifications(user, token_names, days_to_expire: 7)
      notification_service.access_token_about_to_expire(user, token_names, days_to_expire: days_to_expire)
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
