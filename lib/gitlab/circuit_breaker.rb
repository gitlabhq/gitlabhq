# frozen_string_literal: true

# A configurable circuit breaker to protect the application from external service failures.
# The circuit measures the amount of failures and if the threshold is exceeded, stops sending requests.
module Gitlab
  module CircuitBreaker
    InternalServerError = Class.new(StandardError)

    DEFAULT_ERROR_THRESHOLD = 50
    DEFAULT_VOLUME_THRESHOLD = 10

    class << self
      include ::Gitlab::Utils::StrongMemoize

      # @param [String] unique name for the circuit
      # @param options [Hash] an options hash setting optional values per circuit
      def run_with_circuit(service_name, options = {}, &block)
        circuit(service_name, options).run(exception: false, &block)
      end

      private

      def circuit(service_name, options)
        strong_memoize_with(:circuit, service_name, options) do
          circuit_options = {
            exceptions: [InternalServerError],
            error_threshold: DEFAULT_ERROR_THRESHOLD,
            volume_threshold: DEFAULT_VOLUME_THRESHOLD
          }.merge(options)

          Circuitbox.circuit(service_name, circuit_options)
        end
      end
    end
  end
end
