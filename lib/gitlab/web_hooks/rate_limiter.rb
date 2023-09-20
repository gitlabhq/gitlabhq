# frozen_string_literal: true

module Gitlab
  module WebHooks
    class RateLimiter
      include Gitlab::Utils::StrongMemoize

      LIMIT_NAME = :web_hook_calls
      NO_LIMIT = 0
      # SystemHooks (instance admin hooks) and ServiceHooks (integration hooks)
      # are not rate-limited.
      EXCLUDED_HOOK_TYPES = %w[SystemHook ServiceHook].freeze

      def initialize(hook)
        @hook = hook
        @parent = hook.parent
      end

      # Increments the rate-limit counter.
      # Returns true if the hook should be rate-limited.
      def rate_limit!
        return false if no_limit?

        ::Gitlab::ApplicationRateLimiter.throttled?(
          limit_name,
          scope: [root_namespace],
          threshold: limit
        )
      end

      # Returns true if the hook is currently over its rate-limit.
      # It does not increment the rate-limit counter.
      def rate_limited?
        return false if no_limit?

        Gitlab::ApplicationRateLimiter.peek(
          limit_name,
          scope: [root_namespace],
          threshold: limit
        )
      end

      def limit
        strong_memoize(:limit) do
          next NO_LIMIT if hook.class.name.in?(EXCLUDED_HOOK_TYPES)

          root_namespace.actual_limits.limit_for(limit_name) || NO_LIMIT
        end
      end

      private

      attr_reader :hook, :parent

      def no_limit?
        limit == NO_LIMIT
      end

      def root_namespace
        @root_namespace ||= parent.root_ancestor
      end

      def limit_name
        LIMIT_NAME
      end
    end
  end
end

Gitlab::WebHooks::RateLimiter.prepend_mod
