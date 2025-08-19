# frozen_string_literal: true

module DeployTokens
  class ExpiringWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize
    idempotent!

    data_consistency :sticky

    include CronjobQueue

    feature_category :continuous_delivery

    MAX_RUNTIME = 3.minutes
    REQUEUE_DELAY = 2.minutes

    BATCH_SIZE = 100

    def perform(*args)
      @runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)

      notification_intervals.each do |interval|
        process_deploy_tokens(interval)
        break if over_time?
      end

      self.class.perform_in(REQUEUE_DELAY, *args) if over_time?
    end

    private

    attr_reader :runtime_limiter

    delegate :over_time?, to: :runtime_limiter

    def notification_intervals
      DeployToken::NOTIFICATION_INTERVALS.keys
    end

    def process_deploy_tokens(interval = :seven_days)
      scope = DeployToken
        .scope_for_notification_interval(interval)
        .project_token
        .active
        .with_project_owners_and_maintainers
        .ordered_for_keyset_pagination

      iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: scope)

      iterator.each_batch(of: BATCH_SIZE) do |batch|
        tokens_for_update = []

        batch.each do |deploy_token|
          next unless notify_users_of_deploy_token(deploy_token, interval)

          tokens_for_update << deploy_token.id
        end

        if tokens_for_update.any?
          begin
            DeployToken.update_notification_timestamps(tokens_for_update, interval)
          rescue ActiveRecord::ActiveRecordError => e
            Gitlab::ErrorTracking.track_exception(
              e,
              message: "Failed to update deploy token notification timestamps",
              token_ids: tokens_for_update,
              interval: interval
            )
          end
        end

        break if over_time?
      end
    end

    def notify_users_of_deploy_token(deploy_token, interval)
      all_succeeded = true

      # every deploy token is mapped to one project, but a project can have multiple deploy tokens
      project = deploy_token.projects.first
      return false unless project
      return false unless Feature.enabled?(:project_deploy_token_expiring_notifications, project)

      users = project.owners_and_maintainers
      return false if users.empty?

      interval_days = DeployToken.notification_interval(interval)

      users.each do |user|
        with_context(user: user) do
          notification_service.deploy_token_about_to_expire(
            user,
            deploy_token.name,
            project,
            days_to_expire: interval_days
          )
        end
      rescue StandardError => e
        all_succeeded = false
        Gitlab::ErrorTracking.track_exception(
          e,
          message: 'Failed to send notification about expiring project deploy tokens',
          exception_message: e.message,
          deploy_token_id: deploy_token.id,
          project_id: project.id,
          user_id: user.id
        )
      end

      all_succeeded
    end

    def notification_service
      NotificationService.new
    end
    strong_memoize_attr :notification_service
  end
end
