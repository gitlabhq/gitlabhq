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
      # Increments the given key and returns true if the action should
      # be throttled.
      #
      # @param key [Symbol] Key attribute registered in the labkit rate-limit registry
      # @param scope [Array<ActiveRecord>] Array of ActiveRecord models, Strings
      #     or Symbols to scope throttling to a specific request (e.g. per user
      #     per project)
      # @param resource [ActiveRecord] An ActiveRecord model to count an action
      #     for (e.g. limit unique project (resource) downloads (action) to five
      #     per user (scope))
      # @param threshold [Integer] Optional threshold value to override default
      #     one registered in the labkit rate-limit registry
      # @param interval [Integer] Optional interval value to override default
      #     one registered in the labkit rate-limit registry
      # @param users_allowlist [Array<String>] Optional list of usernames to
      #     exclude from the limit. This param will only be functional if Scope
      #     includes a current user.
      # @param peek [Boolean] Optional. When true the key will not be
      #     incremented but the current throttled state will be returned.
      # @param bypass_header [String, nil] Optional. Raw bypass header value,
      #     matched by a synthetic :skip rule (equal to '1') for visibility.
      #     Not flag-gated here; only #throttled_request? checks the rollout flag.
      #
      # @return [Boolean] Whether or not a request should be throttled
      def throttled?(
        key, scope:, resource: nil, threshold: nil, interval: nil, users_allowlist: nil, peek: false,
        bypass_header: nil)
        raise InvalidKeyError, key unless LabkitAdapter.handled?(key)

        validate_scope!(key, scope)

        rule_context = {
          resource_id: resource&.id,
          threshold: threshold,
          interval: interval,
          bypass_header: bypass_header
        }

        _throttled?(
          key,
          scope: scope,
          rule_context: rule_context,
          users_allowlist: users_allowlist,
          peek: peek
        )
      end

      # Increments the resource usage for a given key and returns true if the action should
      # be throttled.
      #
      # @param key [Symbol] Key attribute registered in the labkit rate-limit registry
      # @param scope [<ActiveRecord>] Array of ActiveRecord models, Strings
      #     or Symbols to scope throttling to a specific request (e.g. per user
      #     per project)
      # @param resource_key [Symbol] Key attribute in SafeRequestStore
      # @param threshold [Integer] Threshold value to override default
      #     one registered in the labkit rate-limit registry
      # @param interval [Integer] Interval value to override default
      #     one registered in the labkit rate-limit registry
      #
      # @return [Boolean] Whether or not a request should be throttled
      #
      # Note: unlike #throttled?, this has no bypass_header: option. Callers
      # are cost-mode/Sidekiq resource-usage checks, not HTTP requests, so there
      # is no bypass header to observe here.
      def resource_usage_throttled?(key, scope:, resource_key:, threshold:, interval:, peek: false)
        validate_scope!(key, scope)

        _throttled?(
          key,
          scope: scope,
          rule_context: { threshold: threshold, interval: interval },
          cost: ::Gitlab::SafeRequestStore[resource_key.to_sym].to_f,
          peek: peek
        )
      end

      # Similar to #throttled? above but checks for the bypass header in the request and logs the request when it is over the rate limit
      #
      # @param request [Http::Request] - Web request used to check the header and log
      # @param current_user [User] Current user of the request, it can be nil
      # @param key [Symbol] Key attribute registered in the labkit rate-limit registry
      # @param scope [Array<ActiveRecord>] Array of ActiveRecord models, Strings
      #     or Symbols to scope throttling to a specific request (e.g. per user
      #     per project)
      # @param resource [ActiveRecord] An ActiveRecord model to count an action
      #     for (e.g. limit unique project (resource) downloads (action) to five
      #     per user (scope))
      # @param threshold [Integer] Optional threshold value to override default
      #     one registered in the labkit rate-limit registry
      # @param interval [Integer] Optional interval value to override default
      #     one registered in the labkit rate-limit registry
      # @param users_allowlist [Array<String>] Optional list of usernames to
      #     exclude from the limit. This param will only be functional if Scope
      #     includes a current user.
      # @param peek [Boolean] Optional. When true the key will not be
      #     incremented but the current throttled state will be returned.
      #
      # @return [Boolean] Whether or not a request should be throttled
      #
      # :rate_limiting_rule_bypass_header off keeps the legacy behavior
      # (immediate false); on, bypass traffic reaches labkit's synthetic
      # :skip rule instead, making bypass volume observable via calls_total.
      def throttled_request?(request, current_user, key, scope:, **options)
        header_name = ::Gitlab::Throttle.bypass_header
        bypass_header = request.get_header(header_name) if header_name.present?

        return false if bypass_header == ::Gitlab::Throttle::BYPASS_HEADER_VALUE &&
          !Feature.enabled?(:rate_limiting_rule_bypass_header, Feature.current_request, type: :ops)

        # Only add :bypass_header when there's an actual value to report, so
        # calls without one keep the exact pre-existing argument shape (callers
        # never pass this key themselves, so there's nothing to preserve otherwise).
        options[:bypass_header] = bypass_header if bypass_header

        throttled?(key, scope: scope, **options).tap do |throttled|
          log_request(request, :"#{key}_request_limit", current_user) if throttled
        end
      end

      # Returns the current rate limited state without incrementing the count.
      #
      # @param key [Symbol] Key attribute registered in the labkit rate-limit registry
      # @param scope [Array<ActiveRecord>] Array of ActiveRecord models to scope throttling to a specific request (e.g. per user per project)
      # @param threshold [Integer] Optional threshold value to override default one registered in the labkit rate-limit registry
      # @param interval [Integer] Optional interval value to override default one registered in the labkit rate-limit registry
      # @param users_allowlist [Array<String>] Optional list of usernames to exclude from the limit. This param will only be functional if Scope includes a current user.
      #
      # @return [Boolean] Whether or not a request is currently throttled
      #
      # Note: like #resource_usage_throttled?, this has no bypass_header:
      # option: callers have no request in scope to read one from.
      def peek(key, scope:, threshold: nil, interval: nil, users_allowlist: nil)
        throttled?(key, peek: true, scope: scope, threshold: threshold, interval: interval, users_allowlist: users_allowlist)
      end

      # Returns the interval (in seconds) registered for the given rate limit key.
      #
      # @param key [Symbol] Key attribute registered in the labkit rate-limit registry
      # @return [Integer] The interval value in seconds
      def period_for(key)
        LabkitAdapter.period_for(key)
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

      private

      def _throttled?(key, scope:, rule_context:, cost: nil, users_allowlist: nil, peek: false)
        ::Gitlab::Instrumentation::RateLimitingGates.track(key)
        validate_overrides!(key, rule_context)

        return false if scoped_user_in_allowlist?(scope, users_allowlist)

        threshold_value = rule_context[:threshold] ||
          LabkitAdapter::SupportedRateLimits.limit_for(key, context: rule_context)
        return false if threshold_value == 0

        interval_value = rule_context[:interval] ||
          LabkitAdapter::SupportedRateLimits.period_for(key, context: rule_context)
        return false if interval_value == 0

        resource_id = rule_context[:resource_id]
        return false if resource_id && !LabkitAdapter.set_mode?(key)
        return false if cost && !LabkitAdapter.cost_mode?(key)

        return false unless LabkitAdapter.handled?(key)

        if peek
          LabkitAdapter.run_peek!(key, scope: scope, context: rule_context)
        else
          LabkitAdapter.run!(key, scope: scope, context: rule_context, cost: cost)
        end
      end

      def validate_overrides!(key, rule_context)
        rule = LabkitAdapter::SupportedRateLimits.rule_for(key)

        validate_override!(key, :threshold, rule.limit) unless rule_context[:threshold].nil?
        validate_override!(key, :interval, rule.period) unless rule_context[:interval].nil?
      end

      def validate_override!(key, override_name, rule_value)
        return if LabkitAdapter::SupportedRateLimits.accepts_context?(rule_value)

        rule_attribute = override_name == :threshold ? 'limit' : 'period'

        raise ArgumentError,
          "#{override_name} override is not supported for #{key}. The registered #{rule_attribute} " \
            'does not accept rule_context; ' \
            'register a context-aware callable to accept per-call overrides.'
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
