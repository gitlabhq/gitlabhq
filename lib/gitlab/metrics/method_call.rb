# rubocop:disable Style/ClassVars

module Gitlab
  module Metrics
    # Class for tracking timing information about method calls
    class MethodCall
      include Gitlab::Metrics::Methods
      BASE_LABELS = { module: nil, method: nil }.freeze
      attr_reader :real_time, :cpu_time, :call_count, :labels

      define_histogram :gitlab_method_call_duration_seconds do
        docstring 'Method calls real duration'
        base_labels Transaction::BASE_LABELS.merge(BASE_LABELS)
        buckets [0.01, 0.05, 0.1, 0.5, 1]
        with_feature :prometheus_metrics_method_instrumentation
      end

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

        if above_threshold?
          self.class.gitlab_method_call_duration_seconds.observe(@transaction.labels.merge(labels), real_time)
        end

        retval
      end

      # Returns a Metric instance of the current method call.
      def to_metric
        Metric.new(
          Instrumentation.series,
          {
            duration: real_time.in_milliseconds.to_i,
            cpu_duration: cpu_time.in_milliseconds.to_i,
            call_count: call_count
          },
          method: @name
        )
      end

      # Returns true if the total runtime of this method exceeds the method call
      # threshold.
      def above_threshold?
        real_time.in_milliseconds >= Metrics.method_call_threshold
      end
    end
  end
end
