# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class KubernetesAgentCounter < BaseCounter
      PREFIX = 'kubernetes_agent'
      KNOWN_EVENTS = %w[gitops_sync].freeze

      class << self
        def increment_gitops_sync(incr)
          raise ArgumentError, 'must be greater than or equal to zero' if incr < 0

          # rather then hitting redis for this no-op, we return early
          # note: redis returns the increment, so we mimic this here
          return 0 if incr == 0

          increment_by(redis_key(:gitops_sync), incr)
        end
      end
    end
  end
end
