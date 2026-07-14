# frozen_string_literal: true

module Gitlab
  # This module implements a simple rate limiter that can be used to throttle
  # certain actions. Unlike Rack Attack and Rack::Throttle, which operate at
  # the middleware level, this can be used at the controller or API level.
  # See CheckRateLimit concern for usage.
  module ApplicationRateLimiter
    InvalidKeyError = Class.new(StandardError)
    InvalidScopeError = Class.new(StandardError)

    class << self
      include ::Gitlab::Utils::StrongMemoize
      # Application rate limits
      #
      # Threshold value can be either an Integer or a Proc
      # in order to not evaluate its value every time this method is called
      # and only do that when it's needed.
      def rate_limits # rubocop:disable Metrics/AbcSize
        {
          ai_action: { threshold: -> { application_settings.ai_action_api_rate_limit }, interval: 8.hours },
          auto_rollback_deployment: { threshold: 1, interval: 3.minutes },
          autocomplete_users: { threshold: -> { application_settings.autocomplete_users_limit }, interval: 1.minute },
          autocomplete_users_unauthenticated: { threshold: -> { application_settings.autocomplete_users_unauthenticated_limit }, interval: 1.minute },
          bitbucket_server_import: { threshold: 6, interval: 1.minute },
          bulk_delete_todos: { threshold: 6, interval: 1.minute },
          bulk_import: { threshold: 6, interval: 1.minute },
          ci_job_processed_subscription: { threshold: 50, interval: 1.minute },
          ci_lint: { threshold: -> { application_settings.ci_lint_limit_per_user }, interval: 1.minute },
          ci_pipeline_statuses_subscription: { threshold: 50, interval: 1.minute },
          code_suggestions_api_endpoint: { threshold: -> { application_settings.code_suggestions_api_rate_limit }, interval: 1.minute },
          create_organization_api: { threshold: -> { application_settings.create_organization_api_limit }, interval: 1.minute },
          delete_all_todos: { threshold: 1, interval: 5.minutes },
          deployment_delete: { threshold: 500, interval: 1.minute },
          downstream_pipeline_trigger: {
            threshold: -> { application_settings.downstream_pipeline_trigger_limit_per_project_user_sha }, interval: 1.minute
          },
          email_verification: { threshold: 10, interval: 10.minutes },
          email_verification_code_send: { threshold: 10, interval: 1.hour },
          expanded_diff_files: { threshold: 6, interval: 1.minute },
          feature_library_search: { threshold: 60, interval: 1.minute },
          fetch_google_ip_list: { threshold: 10, interval: 1.minute },
          github_import: { threshold: 6, interval: 1.minute },
          fogbugz_import: { threshold: 1, interval: 1.minute },
          geo_proxy: { threshold: 60, interval: 1.minute },
          gitea_import: { threshold: 6, interval: 1.minute },
          gitlab_shell_operation: { threshold: application_settings.gitlab_shell_operation_limit, interval: 1.minute },
          glql: { threshold: 1, interval: 15.minutes },
          group_api: { threshold: -> { application_settings.group_api_limit }, interval: 1.minute },
          group_archive_unarchive_api: { threshold: -> { application_settings.group_archive_unarchive_api_limit }, interval: 1.minute },
          group_download_export: { threshold: -> { application_settings.group_download_export_limit }, interval: 1.minute },
          group_export: { threshold: -> { application_settings.group_export_limit }, interval: 1.minute },
          group_import: { threshold: -> { application_settings.group_import_limit }, interval: 1.minute },
          group_invited_groups_api: { threshold: -> { application_settings.group_invited_groups_api_limit }, interval: 1.minute },
          group_projects_api: { threshold: -> { application_settings.group_projects_api_limit }, interval: 1.minute },
          group_shared_groups_api: { threshold: -> { application_settings.group_shared_groups_api_limit }, interval: 1.minute },
          groups_api: { threshold: -> { application_settings.groups_api_limit }, interval: 1.minute },
          import_source_user_notification: { threshold: 1, interval: 8.hours },
          issues_create: { threshold: -> { application_settings.issues_create_limit }, interval: 1.minute },
          jobs_index: { threshold: -> { application_settings.project_jobs_api_rate_limit }, interval: 1.minute },
          large_blob_download: { threshold: 5, interval: 1.minute },
          members_delete: { threshold: -> { application_settings.members_delete_limit }, interval: 1.minute },
          namespace_exists: { threshold: 20, interval: 1.minute },
          notes_create: { threshold: -> { application_settings.notes_create_limit }, interval: 1.minute },
          notification_emails: { threshold: 1000, interval: 1.day },
          oauth_dynamic_registration: { threshold: 5, interval: 1.hour },
          offline_export: { threshold: 6, interval: 1.minute },
          offline_import: { threshold: 6, interval: 1.minute },
          permanent_email_failure: { threshold: 5, interval: 1.day },
          phone_verification_send_code: { threshold: 5, interval: 1.day },
          phone_verification_verify_code: { threshold: 5, interval: 1.day },
          pipelines_create: { threshold: -> { application_settings.pipeline_limit_per_project_user_sha }, interval: 1.minute },
          pipelines_created_per_user: { threshold: -> { application_settings.pipeline_limit_per_user }, interval: 1.minute },
          play_pipeline_schedule: { threshold: 1, interval: 1.minute },
          placeholder_reassignment: { threshold: 5, interval: 1.minute },
          profile_add_new_email: { threshold: 5, interval: 1.minute },
          profile_resend_email_confirmation: { threshold: 5, interval: 1.minute },
          profile_update_username: { threshold: 10, interval: 1.minute },
          project_api: { threshold: -> { application_settings.project_api_limit }, interval: 1.minute },
          project_members_api: { threshold: -> { application_settings.project_members_api_limit }, interval: 1.minute },
          project_download_export: { threshold: -> { application_settings.project_download_export_limit }, interval: 1.minute },
          project_export: { threshold: -> { application_settings.project_export_limit }, interval: 1.minute },
          project_fork_sync: { threshold: 10, interval: 30.minutes },
          project_generate_new_export: { threshold: -> { application_settings.project_export_limit }, interval: 1.minute },
          project_import: { threshold: -> { application_settings.project_import_limit }, interval: 1.minute },
          project_invited_groups_api: { threshold: -> { application_settings.project_invited_groups_api_limit }, interval: 1.minute },
          project_repositories_archive: { threshold: 5, interval: 1.minute },
          project_repositories_changelog: { threshold: 5, interval: 1.minute },
          project_repositories_health: { threshold: 5, interval: 1.hour },
          project_testing_integration: { threshold: 5, interval: 1.minute },
          projects_api: { threshold: -> { application_settings.projects_api_limit }, interval: 10.minutes },
          projects_api_rate_limit_unauthenticated: {
            threshold: -> { application_settings.projects_api_rate_limit_unauthenticated }, interval: 10.minutes
          },
          raw_blob: { threshold: -> { application_settings.raw_blob_request_limit }, interval: 1.minute },
          raw_blob_unauthenticated: { threshold: -> { application_settings.raw_blob_request_limit_unauthenticated }, interval: 1.minute },
          runner_jobs_request_api: { threshold: -> { application_settings.runner_jobs_request_api_limit }, interval: 1.minute },
          runner_jobs_patch_trace_api: { threshold: -> { application_settings.runner_jobs_patch_trace_api_limit }, interval: 1.minute },
          runner_jobs_api: { threshold: -> { application_settings.runner_jobs_endpoints_api_limit }, interval: 1.minute },
          search_index_integrity: { threshold: 1, interval: 30.minutes },
          search_rate_limit: { threshold: -> { application_settings.search_rate_limit }, interval: 1.minute },
          search_rate_limit_unauthenticated: { threshold: -> { application_settings.search_rate_limit_unauthenticated }, interval: 1.minute },
          service_account_creation: { threshold: 10, interval: 1.minute },
          temporary_email_failure: { threshold: 300, interval: 1.day },
          token_exchange: { threshold: 60, interval: 1.minute },
          update_environment_canary_ingress: { threshold: 1, interval: 1.minute },
          update_namespace_name: { threshold: -> { application_settings.update_namespace_name_rate_limit }, interval: 1.hour },
          user_large_commit_request: { threshold: 3, interval: 30.seconds },
          user_contributed_projects_api: { threshold: -> { application_settings.user_contributed_projects_api_limit }, interval: 1.minute },
          user_followers: { threshold: -> { application_settings.users_api_limit_followers }, interval: 1.minute },
          user_following: { threshold: -> { application_settings.users_api_limit_following }, interval: 1.minute },
          user_gpg_key: { threshold: -> { application_settings.users_api_limit_gpg_key }, interval: 1.minute },
          user_gpg_keys: { threshold: -> { application_settings.users_api_limit_gpg_keys }, interval: 1.minute },
          user_projects_api: { threshold: -> { application_settings.user_projects_api_limit }, interval: 1.minute },
          user_sign_in: { threshold: 5, interval: 10.minutes },
          user_sign_up: { threshold: 20, interval: 1.minute },
          user_ssh_key: { threshold: -> { application_settings.users_api_limit_ssh_key }, interval: 1.minute },
          user_ssh_keys: { threshold: -> { application_settings.users_api_limit_ssh_keys }, interval: 1.minute },
          user_starred_projects_api: { threshold: -> { application_settings.user_starred_projects_api_limit }, interval: 1.minute },
          user_status: { threshold: -> { application_settings.users_api_limit_status }, interval: 1.minute },
          username_exists: { threshold: 20, interval: 1.minute },
          users_get_by_id: { threshold: -> { application_settings.users_get_by_id_limit }, interval: 10.minutes },
          web_hook_calls: { interval: 1.minute },
          web_hook_calls_low: { interval: 1.minute },
          web_hook_calls_mid: { interval: 1.minute },
          web_hook_event_resend: { threshold: 5, interval: 1.minute },
          web_hook_test: { threshold: 5, interval: 1.minute }
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
        raise InvalidKeyError, key unless rate_limits[key]

        validate_scope!(key, scope)

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
      def resource_usage_throttled?(key, scope:, resource_key:, threshold:, interval:, peek: false)
        validate_scope!(key, scope)

        strategy = IncrementResourceUsagePerAction.new(resource_key)

        _throttled?(key, scope: scope, strategy: strategy, threshold: threshold, interval: interval, peek: peek)
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
          log_request(request, :"#{key}_request_limit", current_user) if throttled
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
          method: request.request_method,
          path: request_path(request)
        }

        if current_user
          request_information.merge!(
            user_id: current_user.id,
            username: current_user.username
          )
        end

        logger.error(request_information)
      end

      # Returns the interval value for a given rate limit key
      #
      # @param key [Symbol] Key attribute registered in `.rate_limits`
      # @return [Integer, nil] The interval value in seconds, or nil if not configured
      def interval(key)
        value = limit_source_value(key, :interval, :period)
        raise InvalidKeyError if value.nil?

        rate_limit_value(value)
      end

      # Returns the threshold value for a given rate limit key, resolving any
      # Proc against the current application settings.
      #
      # @param key [Symbol] Key attribute registered in `.rate_limits`
      # @return [Integer] The resolved threshold; 0 when the key disables itself.
      def threshold(key)
        value = limit_source_value(key, :threshold, :limit)

        rate_limit_value(value)
      end

      private

      def _throttled?(key, scope:, strategy:, threshold: nil, interval: nil, users_allowlist: nil, peek: false)
        ::Gitlab::Instrumentation::RateLimitingGates.track(key)

        return false if scoped_user_in_allowlist?(scope, users_allowlist)

        threshold_value = threshold || threshold(key)
        return false if threshold_value == 0

        interval_value = interval || interval(key)
        return false if interval_value == 0

        # Threshold/interval are passed through as per-call overrides; the
        # labkit Rule resolves them (falling back to the registry) per check.
        labkit_decision = dispatch_to_labkit(
          key,
          scope: scope,
          strategy: strategy,
          peek: peek,
          threshold: threshold,
          interval: interval
        )

        # Keys not handled by the adapter (absent from the labkit registry, or
        # an INCR-mode key called with a resource) return nil; treat that as
        # "not throttled". A guardrail spec asserts every rate_limits key is
        # registered, so this does not silently disable a real limit.
        return false if labkit_decision.nil?

        labkit_decision
      end

      # Routes a check through the labkit adapter when the strategy maps to the
      # registered labkit rule mode, returning labkit's boolean decision or nil
      # if the strategy/rule combination is intentionally not dispatched.
      # Plain IncrementPerAction maps to labkit's INCR-mode rules;
      # IncrementPerActionedResource maps to labkit's count_distinct (SADD)
      # rules with +resource_id+ as the SET member. IncrementResourceUsagePerAction
      # maps to labkit cost-mode rules (caller-supplied threshold/interval),
      # passing the per-request consumption as labkit `check(cost:)`. Peek
      # dispatches to a read-only Redis round-trip so the labkit counter only
      # advances via paired non-peek call sites.
      def dispatch_to_labkit(key, scope:, strategy:, peek:, threshold:, interval:)
        resource_id = nil
        cost = nil
        case strategy
        when IncrementPerAction
          # INCR-mode strategy maps to any non-count_distinct labkit rule.
        when IncrementPerActionedResource
          # SADD/SCARD-mode strategy is only equivalent to a count_distinct
          # labkit rule. For INCR-mode keys called with a resource (e.g. an
          # ad-hoc test call to a cohort 1-3 key with resource:) the labkit
          # counter would diverge silently from legacy, so stay on legacy.
          return unless LabkitAdapter.set_mode?(key)

          resource_id = strategy.resource_key
        when IncrementResourceUsagePerAction
          # Cost-mode: per-worker resource-usage accumulation. Cost is the
          # resource consumed this request (read from SafeRequestStore via the
          # strategy's resource_key); threshold/interval are the SidekiqLimits-
          # resolved (override-aware) values passed by resource_usage_throttled?.
          return unless LabkitAdapter.cost_mode?(key)

          cost = ::Gitlab::SafeRequestStore[strategy.resource_key.to_sym].to_f
        else
          return
        end

        context = { resource_id: resource_id, threshold: threshold, interval: interval }

        if peek
          LabkitAdapter.run_peek!(key, scope: scope, context: context)
        else
          LabkitAdapter.run!(key, scope: scope, context: context, cost: cost)
        end
      end

      def rate_limit_value(value)
        value = value.call if value.is_a?(Proc)

        value.to_i
      end

      def rate_limit_value_by_key(key, setting)
        action = rate_limits[key]

        action[setting] if action
      end

      # Returns the raw (unresolved) limit/period source for a key.
      #
      # The labkit SupportedRateLimits registry now carries each key's
      # limit/period and is migrating toward being the single source of truth
      # (see gitlab-com/gl-infra/production-engineering#29054). While the
      # rate_limiter_resolve_limits_from_registry flag is enabled this reads the
      # registry; while disabled it reads the legacy rate_limits hash. A parity
      # spec asserts the two resolve to identical values for every key, so the
      # flag is a value-preserving switch.
      #
      # @param key [Symbol] the rate limit key
      # @param rate_limits_field [Symbol] :threshold or :interval (legacy hash)
      # @param registry_field [Symbol] :limit or :period (registry entry)
      def limit_source_value(key, rate_limits_field, registry_field)
        if Feature.enabled?(:rate_limiter_resolve_limits_from_registry, Feature.current_request)
          LabkitAdapter::SupportedRateLimits.all.dig(key, registry_field)
        else
          rate_limit_value_by_key(key, rate_limits_field)
        end
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

      def validate_scope!(key, scope, logger = Gitlab::AuthLogger)
        return if scope

        logger.warn(
          message: 'Application_Rate_Limiter_Request_Without_Scope',
          env: :"#{key}_request_limit"
        )

        raise InvalidScopeError, 'scope cannot be nil. Use :global for global rate limits.'
      end
    end
  end
end

Gitlab::ApplicationRateLimiter.prepend_mod
