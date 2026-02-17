# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class CircuitBreaker
      module State
        CLOSED = 'closed'
        OPEN = 'open'
      end

      module Result
        ALLOWED = 'allowed'
        REJECTED = 'rejected'
        ERROR = 'error'
      end

      module Reason
        RESOURCE_EXHAUSTED = 'resource_exhausted'
      end

      def initialize(service:, rpc:, storage:)
        @service = service
        @rpc = rpc
        @storage = storage
      end

      def call
        return yield unless enabled?
        return yield if authenticated_request?

        previous_state = current_circuit_state

        circuit.run(exception: true) do
          result = yield
          Metrics.track_request(circuit_state: previous_state, result: Result::ALLOWED)
          result
        end
      # ServiceFailureError: Circuit is closed, request was attempted but failed.
      # Re-raise the original exception to preserve error details.
      rescue Circuitbox::ServiceFailureError => e
        Metrics.track_request(circuit_state: previous_state, result: Result::ERROR, reason: Reason::RESOURCE_EXHAUSTED)
        track_state_transition(previous_state)
        raise e.original
      # OpenCircuitError: Circuit is open due to too many failures.
      # No request was attempted. Convert to ResourceExhaustedError with context.
      rescue Circuitbox::OpenCircuitError
        raise_open_circuit_exception!
      end

      def check!
        return unless enabled?
        return if authenticated_request?
        return unless circuit.open?

        raise_open_circuit_exception!
      end

      private

      attr_reader :service, :rpc, :storage

      def enabled?
        Feature.enabled?(:add_circuit_breaker_to_gitaly, Feature.current_request)
      end

      def circuit
        @circuit ||= Circuitbox.circuit(circuit_name, circuit_options)
      end

      def circuit_name
        "gitaly:circuit_breaker:{#{storage}:#{service}:#{rpc}}"
      end

      def raise_open_circuit_exception!
        Metrics.track_request(
          circuit_state: State::OPEN,
          result: Result::REJECTED
        )
        raise Gitlab::Git::ResourceExhaustedError, "Gitaly service temporarily unavailable. Circuit is open"
      end

      def endpoint_label
        "#{service}:#{rpc}"
      end

      def authenticated_request?
        Gitlab::ApplicationContext.current['meta.user'].present?
      end

      def circuit_options
        {
          exceptions: [GRPC::ResourceExhausted],
          volume_threshold: 5,
          error_threshold: 50,
          sleep_window: 60,
          time_window: 60
        }
      end

      def current_circuit_state
        circuit.open? ? State::OPEN : State::CLOSED
      end

      def track_state_transition(previous_state)
        new_state = current_circuit_state
        return if previous_state == new_state

        Metrics.track_state_transition(
          endpoint: endpoint_label,
          storage: storage,
          from_state: previous_state,
          to_state: new_state
        )
      end
    end
  end
end
