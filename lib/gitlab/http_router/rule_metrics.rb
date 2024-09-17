# frozen_string_literal: true

module Gitlab
  module HttpRouter
    module RuleMetrics
      extend ActiveSupport::Concern

      include HttpRouter::RuleContext
      include Gitlab::Utils::StrongMemoize

      def increment_http_router_metrics
        context = http_router_rule_context
        increment_http_router_rule_counter(context[:http_router_rule_action], context[:http_router_rule_type])
      end

      private

      def increment_http_router_rule_counter(http_router_rule_action, http_router_rule_type)
        # `action` should be present, but `type` is optional
        return if http_router_rule_action.blank?

        labels = {
          rule_action: http_router_rule_action,
          rule_type: http_router_rule_type
        }

        http_router_rule_counter.increment(labels)
      end

      def http_router_rule_counter
        name = :gitlab_http_router_rule_total
        comment = 'Total number of HTTP router rule invocations'

        ::Gitlab::Metrics.counter(name, comment)
      end
      strong_memoize_attr :http_router_rule_counter
    end
  end
end
