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
      project = deploy_token.projects.first
      return false unless project && Feature.enabled?(:project_deploy_token_expiring_notifications, project)

      users = project.owners_and_maintainers

      return false if users.empty?

      interval_days = DeployToken.notification_interval(interval)
      all_succeeded = true

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
        log_error(e, 'Failed to send notification about expiring project deploy tokens',
          deploy_token, project, user_id: user.id)
      end

      # Execute webhooks
      begin
        execute_resource_deploy_token_web_hooks(deploy_token, interval)
      rescue StandardError => e
        all_succeeded = false
        log_error(e, 'Failed to execute webhooks for expiring project deploy token',
          deploy_token, project)
      end

      all_succeeded
    end

    def execute_resource_deploy_token_web_hooks(deploy_token, interval)
      resources = deploy_token.project_type? ? deploy_token.projects : deploy_token.groups

      resources.each do |resource|
        next unless resource.has_active_hooks?(:resource_deploy_token_hooks)

        hook_data = Gitlab::DataBuilder::ResourceDeployTokenPayload.build(
          deploy_token,
          :expiring,
          resource,
          { interval: interval }
        )

        resource.execute_hooks(hook_data, :resource_deploy_token_hooks)
      end
    end

    def log_error(exception, message, deploy_token, project, additional_data = {})
      Gitlab::ErrorTracking.track_exception(
        exception,
        {
          message: message,
          exception_message: exception.message,
          deploy_token_id: deploy_token.id,
          project_id: project.id
        }.merge(additional_data)
      )
    end

    def notification_service
      NotificationService.new
    end
    strong_memoize_attr :notification_service
  end
end
