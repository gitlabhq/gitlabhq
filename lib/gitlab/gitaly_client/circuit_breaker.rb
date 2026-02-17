# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class CircuitBreaker
      def initialize(service:, rpc:, storage:)
        @service = service
        @rpc = rpc
        @storage = storage
      end

      def call
        return yield unless enabled?
        return yield if authenticated_request?

        circuit.run(exception: true) do
          yield
        end
      # ServiceFailureError: Circuit is closed/half-open, request was attempted but failed.
      # Re-raise the original exception to preserve error details.
      rescue Circuitbox::ServiceFailureError => e
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
        raise Gitlab::Git::ResourceExhaustedError, "Gitaly service temporarily unavailable. Circuit is open"
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
    end
  end
end
