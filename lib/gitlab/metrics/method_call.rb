# frozen_string_literal: true

module Gitlab
  module Metrics
    # Class for tracking timing information about method calls
    class MethodCall
      attr_reader :real_time, :cpu_time, :call_count

      # name - The full name of the method (including namespace) such as
      #        `User#sign_in`.
      #
      def initialize(name, module_name, method_name, transaction)
        @module_name = module_name
        @method_name = method_name
        @transaction = transaction
        @name = name
        @labels = { module: @module_name, method: @method_name }
        @real_time = 0.0
        @cpu_time = 0.0
        @call_count = 0
      end

      # Measures the real and CPU execution time of the supplied block.
      def measure
        start_real = System.monotonic_time
        start_cpu = System.cpu_time
        retval = yield

        real_time = System.monotonic_time - start_real
        cpu_time = System.cpu_time - start_cpu

        @real_time += real_time
        @cpu_time += cpu_time
        @call_count += 1

        if above_threshold? && transaction
          label_keys = labels.keys
          transaction.observe(:gitlab_method_call_duration_seconds, real_time, labels) do
            docstring 'Method calls real duration'
            label_keys label_keys
            buckets [0.01, 0.05, 0.1, 0.5, 1]
          end
        end

        retval
      end

      # Returns true if the total runtime of this method exceeds the method call
      # threshold.
      def above_threshold?
        real_time.in_milliseconds >= ::Gitlab::Metrics.method_call_threshold
      end

      private

      attr_reader :labels, :transaction
    end
  end
end
