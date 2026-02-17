# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class CircuitBreaker
      class Metrics
        class << self
          def track_request(circuit_state:, result:, reason: '')
            requests_total.increment(
              circuit_state: circuit_state,
              result: result,
              reason: reason
            )
          end

          def track_state_transition(endpoint:, storage:, from_state:, to_state:)
            transitions_total.increment(
              from_state: from_state,
              to_state: to_state
            )

            Gitlab::AppLogger.info(
              message: 'Gitaly circuit breaker state transition',
              endpoint: endpoint,
              storage: storage,
              from_state: from_state,
              to_state: to_state
            )
          end

          def requests_total
            @requests_total ||= ::Gitlab::Metrics.counter(
              :gitaly_circuit_breaker_requests_total,
              'Total Gitaly requests processed by circuit breaker',
              { circuit_state: nil, result: nil, reason: nil }
            )
          end

          def transitions_total
            @transitions_total ||= ::Gitlab::Metrics.counter(
              :gitaly_circuit_breaker_transitions_total,
              'Total number of circuit breaker state transitions',
              { from_state: nil, to_state: nil }
            )
          end
        end
      end
    end
  end
end
