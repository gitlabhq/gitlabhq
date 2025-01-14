# frozen_string_literal: true

module Gitlab
  # This module implements a simple rate limiter that can be used to throttle
  # certain actions. Unlike Rack Attack and Rack::Throttle, which operate at
  # the middleware level, this can be used at the controller or API level.
  # See CheckRateLimit concern for usage.
  module ApplicationRateLimiter
    InvalidKeyError = Class.new(StandardError)

    LIMIT_USAGE_BUCKET = [0.25, 0.5, 0.75, 1].freeze

    class << self
      include ::Gitlab::Utils::StrongMemoize
      # Application rate limits
      #
      # Threshold value can be either an Integer or a Proc
      # in order to not evaluate it's value every time this method is called
      # and only do that when it's needed.
      def rate_limits # rubocop:disable Metrics/AbcSize
        {
          issues_create: { threshold: -> { application_settings.issues_create_limit }, interval: 1.minute },
          notes_create: { threshold: -> { application_settings.notes_create_limit }, interval: 1.minute },
          project_export: { threshold: -> { application_settings.project_export_limit }, interval: 1.minute },
          project_download_export: { threshold: -> { application_settings.project_download_export_limit }, interval: 1.minute },
          project_repositories_archive: { threshold: 5, interval: 1.minute },
          project_repositories_changelog: { threshold: 5, interval: 1.minute },
          project_generate_new_export: { threshold: -> { application_settings.project_export_limit }, interval: 1.minute },
          project_import: { threshold: -> { application_settings.project_import_limit }, interval: 1.minute },
          play_pipeline_schedule: { threshold: 1, interval: 1.minute },
          raw_blob: { threshold: -> { application_settings.raw_blob_request_limit }, interval: 1.minute },
          group_export: { threshold: -> { application_settings.group_export_limit }, interval: 1.minute },
          group_download_export: { threshold: -> { application_settings.group_download_export_limit }, interval: 1.minute },
          group_import: { threshold: -> { application_settings.group_import_limit }, interval: 1.minute },
          group_api: { threshold: -> { application_settings.group_api_limit }, interval: 1.minute },
          group_invited_groups_api: { threshold: -> { application_settings.group_invited_groups_api_limit }, interval: 1.minute },
          group_shared_groups_api: { threshold: -> { application_settings.group_shared_groups_api_limit }, interval: 1.minute },
          group_projects_api: { threshold: -> { application_settings.group_projects_api_limit }, interval: 1.minute },
          groups_api: { threshold: -> { application_settings.groups_api_limit }, interval: 1.minute },
          project_api: { threshold: -> { application_settings.project_api_limit }, interval: 1.minute },
          create_organization_api: { threshold: -> { application_settings.create_organization_api_limit }, interval: 1.minute },
          project_invited_groups_api: { threshold: -> { application_settings.project_invited_groups_api_limit }, interval: 1.minute },
          projects_api: { threshold: -> { application_settings.projects_api_limit }, interval: 10.minutes },
          user_contributed_projects_api: { threshold: -> { application_settings.user_contributed_projects_api_limit }, interval: 1.minute },
          user_projects_api: { threshold: -> { application_settings.user_projects_api_limit }, interval: 1.minute },
          user_starred_projects_api: { threshold: -> { application_settings.user_starred_projects_api_limit }, interval: 1.minute },
          members_delete: { threshold: -> { application_settings.members_delete_limit }, interval: 1.minute },
          profile_add_new_email: { threshold: 5, interval: 1.minute },
          web_hook_calls: { interval: 1.minute },
          web_hook_calls_mid: { interval: 1.minute },
          web_hook_calls_low: { interval: 1.minute },
          web_hook_test: { threshold: 5, interval: 1.minute },
          web_hook_event_resend: { threshold: 5, interval: 1.minute },
          users_get_by_id: { threshold: -> { application_settings.users_get_by_id_limit }, interval: 10.minutes },
          username_exists: { threshold: 20, interval: 1.minute },
          user_followers: { threshold: 100, interval: 1.minute },
          user_following: { threshold: 100, interval: 1.minute },
          user_status: { threshold: 240, interval: 1.minute },
          user_keys: { threshold: 120, interval: 1.minute },
          user_specific_key: { threshold: 120, interval: 1.minute },
          user_gpg_keys: { threshold: 120, interval: 1.minute },
          user_specific_gpg_key: { threshold: 120, interval: 1.minute },
          user_sign_up: { threshold: 20, interval: 1.minute },
          user_sign_in: { threshold: 5, interval: 10.minutes },
          profile_resend_email_confirmation: { threshold: 5, interval: 1.minute },
          profile_update_username: { threshold: 10, interval: 1.minute },
          update_environment_canary_ingress: { threshold: 1, interval: 1.minute },
          auto_rollback_deployment: { threshold: 1, interval: 3.minutes },
          search_rate_limit: { threshold: -> { application_settings.search_rate_limit }, interval: 1.minute },
          search_rate_limit_unauthenticated: { threshold: -> { application_settings.search_rate_limit_unauthenticated }, interval: 1.minute },
          gitlab_shell_operation: { threshold: application_settings.gitlab_shell_operation_limit, interval: 1.minute },
          pipelines_create: { threshold: -> { application_settings.pipeline_limit_per_project_user_sha }, interval: 1.minute },
          temporary_email_failure: { threshold: 300, interval: 1.day },
          permanent_email_failure: { threshold: 5, interval: 1.day },
          notification_emails: { threshold: 1000, interval: 1.day },
          project_testing_integration: { threshold: 5, interval: 1.minute },
          email_verification: { threshold: 10, interval: 10.minutes },
          email_verification_code_send: { threshold: 10, interval: 1.hour },
          phone_verification_send_code: { threshold: 5, interval: 1.day },
          phone_verification_verify_code: { threshold: 5, interval: 1.day },
          namespace_exists: { threshold: 20, interval: 1.minute },
          update_namespace_name: { threshold: -> { application_settings.update_namespace_name_rate_limit }, interval: 1.hour },
          fetch_google_ip_list: { threshold: 10, interval: 1.minute },
          project_fork_sync: { threshold: 10, interval: 30.minutes },
          ai_action: { threshold: -> { application_settings.ai_action_api_rate_limit }, interval: 8.hours },
          code_suggestions_api_endpoint: { threshold: -> { application_settings.code_suggestions_api_rate_limit }, interval: 1.minute },
          vertex_embeddings_api: { threshold: 450, interval: 1.minute },
          jobs_index: { threshold: -> { application_settings.project_jobs_api_rate_limit }, interval: 1.minute },
          bulk_import: { threshold: 6, interval: 1.minute },
          fogbugz_import: { threshold: 1, interval: 1.minute },
          import_source_user_notification: { threshold: 1, interval: 8.hours },
          projects_api_rate_limit_unauthenticated: {
            threshold: -> { application_settings.projects_api_rate_limit_unauthenticated }, interval: 10.minutes
          },
          downstream_pipeline_trigger: {
            threshold: -> { application_settings.downstream_pipeline_trigger_limit_per_project_user_sha }, interval: 1.minute
          },
          expanded_diff_files: { threshold: 6, interval: 1.minute }
        }.freeze
      end

      # Increments the given key and returns true if the action should
      # be throttled.
      #
      # @param key [Symbol] Key attribute registered in `.rate_limits`
      # @param scope [Array<ActiveRecord>] Array of ActiveRecord models, Strings
      #     or Symbols to scope throttling to a specific request (e.g. per user
      #     per project)
      # @param resource [ActiveRecord] An ActiveRecord model to count an action
      #     for (e.g. limit unique project (resource) downloads (action) to five
      #     per user (scope))
      # @param threshold [Integer] Optional threshold value to override default
      #     one registered in `.rate_limits`
      # @param interval [Integer] Optional interval value to override default
      #     one registered in `.rate_limits`
      # @param users_allowlist [Array<String>] Optional list of usernames to
      #     exclude from the limit. This param will only be functional if Scope
      #     includes a current user.
      # @param peek [Boolean] Optional. When true the key will not be
      #     incremented but the current throttled state will be returned.
      #
      # @return [Boolean] Whether or not a request should be throttled
      def throttled?(key, scope:, resource: nil, threshold: nil, interval: nil, users_allowlist: nil, peek: false)
        raise InvalidKeyError unless rate_limits[key]

        strategy = resource.present? ? IncrementPerActionedResource.new(resource.id) : IncrementPerAction.new

        _throttled?(key, scope: scope, strategy: strategy, threshold: threshold, interval: interval, users_allowlist: users_allowlist, peek: peek)
      end

      # Increments the resource usage for a given key and returns true if the action should
      # be throttled.
      #
      # @param key [Symbol] Key attribute registered in `.rate_limits`
      # @param scope [<ActiveRecord>] Array of ActiveRecord models, Strings
      #     or Symbols to scope throttling to a specific request (e.g. per user
      #     per project)
      # @param resource_key [Symbol] Key attribute in SafeRequestStore
      # @param threshold [Integer] Threshold value to override default
      #     one registered in `.rate_limits`
      # @param interval [Integer] Interval value to override default
      #     one registered in `.rate_limits`
      #
      # @return [Boolean] Whether or not a request should be throttled
      def resource_usage_throttled?(key, scope:, resource_key:, threshold:, interval:)
        strategy = IncrementResourceUsagePerAction.new(resource_key)

        _throttled?(key, scope: scope, strategy: strategy, threshold: threshold, interval: interval)
      end

      # Similar to #throttled? above but checks for the bypass header in the request and logs the request when it is over the rate limit
      #
      # @param request [Http::Request] - Web request used to check the header and log
      # @param current_user [User] Current user of the request, it can be nil
      # @param key [Symbol] Key attribute registered in `.rate_limits`
      # @param scope [Array<ActiveRecord>] Array of ActiveRecord models, Strings
      #     or Symbols to scope throttling to a specific request (e.g. per user
      #     per project)
      # @param resource [ActiveRecord] An ActiveRecord model to count an action
      #     for (e.g. limit unique project (resource) downloads (action) to five
      #     per user (scope))
      # @param threshold [Integer] Optional threshold value to override default
      #     one registered in `.rate_limits`
      # @param interval [Integer] Optional interval value to override default
      #     one registered in `.rate_limits`
      # @param users_allowlist [Array<String>] Optional list of usernames to
      #     exclude from the limit. This param will only be functional if Scope
      #     includes a current user.
      # @param peek [Boolean] Optional. When true the key will not be
      #     incremented but the current throttled state will be returned.
      #
      # @return [Boolean] Whether or not a request should be throttled
      def throttled_request?(request, current_user, key, scope:, **options)
        if ::Gitlab::Throttle.bypass_header.present? && request.get_header(Gitlab::Throttle.bypass_header) == '1'
          return false
        end

        throttled?(key, scope: scope, **options).tap do |throttled|
          log_request(request, "#{key}_request_limit".to_sym, current_user) if throttled
        end
      end

      # Returns the current rate limited state without incrementing the count.
      #
      # @param key [Symbol] Key attribute registered in `.rate_limits`
      # @param scope [Array<ActiveRecord>] Array of ActiveRecord models to scope throttling to a specific request (e.g. per user per project)
      # @param threshold [Integer] Optional threshold value to override default one registered in `.rate_limits`
      # @param interval [Integer] Optional interval value to override default one registered in `.rate_limits`
      # @param users_allowlist [Array<String>] Optional list of usernames to exclude from the limit. This param will only be functional if Scope includes a current user.
      #
      # @return [Boolean] Whether or not a request is currently throttled
      def peek(key, scope:, threshold: nil, interval: nil, users_allowlist: nil)
        throttled?(key, peek: true, scope: scope, threshold: threshold, interval: interval, users_allowlist: users_allowlist)
      end

      def report_metrics(key, value, threshold, peek)
        return if threshold == 0 # guard against div-by-zero

        label = {
          throttle_key: key,
          peek: peek,
          feature_category: Gitlab::ApplicationContext.current_context_attribute(:feature_category)
        }
        application_rate_limiter_histogram.observe(label, value / threshold.to_f)
      end

      def application_rate_limiter_histogram
        @application_rate_limiter_histogram ||= Gitlab::Metrics.histogram(
          :gitlab_application_rate_limiter_throttle_utilization_ratio,
          "The utilization-ratio of a throttle.",
          { peek: nil, throttle_key: nil, feature_category: nil },
          LIMIT_USAGE_BUCKET
        )
      end

      # Logs request using provided logger
      #
      # @param request [Http::Request] - Web request to be logged
      # @param type [Symbol] A symbol key that represents the request
      # @param current_user [User] Current user of the request, it can be nil
      # @param logger [Logger] Logger to log request to a specific log file. Defaults to Gitlab::AuthLogger
      def log_request(request, type, current_user, logger = Gitlab::AuthLogger)
        request_information = {
          message: 'Application_Rate_Limiter_Request',
          env: type,
          remote_ip: request.ip,
          request_method: request.request_method,
          path: request_path(request)
        }

        if current_user
          request_information.merge!({
                                       user_id: current_user.id,
                                       username: current_user.username
                                     })
        end

        logger.error(request_information)
      end

      private

      def _throttled?(key, scope:, strategy:, threshold: nil, interval: nil, users_allowlist: nil, peek: false)
        ::Gitlab::Instrumentation::RateLimitingGates.track(key)

        return false if scoped_user_in_allowlist?(scope, users_allowlist)

        threshold_value = threshold || threshold(key)

        return false if threshold_value == 0

        interval_value = interval || interval(key)

        return false if interval_value == 0

        # `period_key` is based on the current time and interval so when time passes to the next interval
        # the key changes and the rate limit count starts again from 0.
        # Based on https://github.com/rack/rack-attack/blob/886ba3a18d13c6484cd511a4dc9b76c0d14e5e96/lib/rack/attack/cache.rb#L63-L68
        period_key, time_elapsed_in_period = Time.now.to_i.divmod(interval_value)
        cache_key = cache_key(key, scope, period_key)

        value = if peek
                  strategy.read(cache_key)
                else
                  # We add a 1 second buffer to avoid timing issues when we're at the end of a period
                  expiry = interval_value - time_elapsed_in_period + 1

                  strategy.increment(cache_key, expiry)
                end

        report_metrics(key, value, threshold_value, peek)

        value > threshold_value
      end

      def threshold(key)
        value = rate_limit_value_by_key(key, :threshold)

        rate_limit_value(value)
      end

      def interval(key)
        value = rate_limit_value_by_key(key, :interval)

        rate_limit_value(value)
      end

      def rate_limit_value(value)
        value = value.call if value.is_a?(Proc)

        value.to_i
      end

      def rate_limit_value_by_key(key, setting)
        action = rate_limits[key]

        action[setting] if action
      end

      def cache_key(key, scope, period_key)
        composed_key = [key, scope].flatten.compact

        serialized = composed_key.map do |obj|
          if obj.is_a?(String) || obj.is_a?(Symbol)
            obj.to_s
          else
            "#{obj.class.model_name.to_s.underscore}:#{obj.id}"
          end
        end.join(":")

        "application_rate_limiter:#{serialized}:#{period_key}"
      end

      def application_settings
        Gitlab::CurrentSettings.current_application_settings
      end

      def scoped_user_in_allowlist?(scope, users_allowlist)
        return unless users_allowlist.present?

        scoped_user = [scope].flatten.find { |s| s.is_a?(User) }
        return unless scoped_user

        username = scoped_user.username.downcase
        users_allowlist.any? { |u| u.downcase == username }
      end

      def request_path(request)
        # req is an ActionDispatch::Request
        if request.respond_to?(:filtered_path)
          request.filtered_path
        else
          # req is a Grape::Request < Rack::Request
          other_filtered_path(request)
        end
      end

      def other_filtered_path(request)
        filtered_params = initialize_filtered_params.filter(request.GET)

        if filtered_params.any?
          "#{request.path}?#{filtered_params.to_query}"
        else
          request.fullpath
        end
      end

      def initialize_filtered_params
        ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      end
      strong_memoize_attr :initialize_filtered_params
    end
  end
end

Gitlab::ApplicationRateLimiter.prepend_mod
