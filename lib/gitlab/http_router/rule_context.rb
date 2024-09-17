# frozen_string_literal: true

module Gitlab
  module HttpRouter
    module RuleContext
      extend ActiveSupport::Concern
      include Gitlab::Utils::StrongMemoize

      # This module is used to log the headers set by the HTTP Router.
      # Refer: https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/src/header.ts
      # to obtain the list of headers.
      #
      # Usage:
      # 1. Include this concern in base controller:
      #      include Gitlab::HttpRouter::RuleContext
      #    Or, in the API layer as a helper
      #      helpers Gitlab::HttpRouter::RuleContext
      #
      # 2. Use the `http_router_rule_context` method when pushing to Gitlab::ApplicationContext:
      #    Gitlab::ApplicationContext.push(**router_rule_context)

      # These values should be kept in sync with the values in the HTTP Router.
      # https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/src/rules/types.d.ts

      ALLOWED_ROUTER_RULE_ACTIONS = %w[classify proxy].freeze
      # We do not expect a type for `proxy` rules
      ROUTER_RULE_ACTIONS_WITHOUT_TYPE = %w[proxy].freeze
      ALLOWED_ROUTER_RULE_TYPES = %w[FIRST_CELL SESSION_PREFIX].freeze

      private

      def http_router_rule_context
        {
          http_router_rule_action: sanitized_http_router_rule_action,
          http_router_rule_type: sanitized_http_router_rule_type
        }
      end

      def sanitized_http_router_rule_action
        sanitize_value(
          request.headers['X-Gitlab-Http-Router-Rule-Action'],
          ALLOWED_ROUTER_RULE_ACTIONS
        )
      end
      strong_memoize_attr :sanitized_http_router_rule_action

      def sanitized_http_router_rule_type
        sanitize_router_rule_type(
          request.headers['X-Gitlab-Http-Router-Rule-Type'],
          sanitized_http_router_rule_action,
          ALLOWED_ROUTER_RULE_TYPES
        )
      end

      def sanitize_value(value, allowed_values)
        return if value.blank?

        allowed_values.include?(value) ? value : nil
      end

      def sanitize_router_rule_type(value, sanitized_http_router_rule_action, allowed_values)
        # Considerations:
        # - `type` cannot exist without an `action`
        # - Some actions (`proxy`) are not expected to have a corresponding `type`, so we perform an early return.
        return if sanitized_http_router_rule_action.blank?
        return if ROUTER_RULE_ACTIONS_WITHOUT_TYPE.include?(sanitized_http_router_rule_action)

        sanitize_value(value, allowed_values)
      end
    end
  end
end
