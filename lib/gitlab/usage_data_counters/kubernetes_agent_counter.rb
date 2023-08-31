# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class KubernetesAgentCounter < BaseCounter
      PREFIX = 'kubernetes_agent'
      KNOWN_EVENTS = %w[
        gitops_sync
        k8s_api_proxy_request
        flux_git_push_notifications_total
        k8s_api_proxy_requests_via_ci_access
        k8s_api_proxy_requests_via_user_access
        k8s_api_proxy_requests_via_pat_access
      ].freeze

      class << self
        def increment_event_counts(events)
          return unless events.present?

          validate!(events)

          events.each do |event, incr|
            # rather then hitting redis for this no-op, we return early
            next if incr == 0

            increment_by(redis_key(event), incr)
          end
        end

        private

        def validate!(events)
          events.each do |event, incr|
            raise ArgumentError, "unknown event #{event}" unless event.in?(KNOWN_EVENTS)
            raise ArgumentError, "#{event} count must be greater than or equal to zero" if incr < 0
          end
        end
      end
    end
  end
end
