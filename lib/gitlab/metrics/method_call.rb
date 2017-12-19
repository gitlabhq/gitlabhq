module Gitlab
  module Metrics
    # Class for tracking timing information about method calls
    class MethodCall
      MUTEX = Mutex.new
      BASE_LABELS = { module: nil, method: nil }.freeze
      attr_reader :real_time_seconds, :cpu_time, :call_count, :labels

      def self.call_duration_histogram
        return @call_duration_histogram if @call_duration_histogram

        MUTEX.synchronize do
          @call_duration_histogram ||= Gitlab::Metrics.histogram(
            :gitlab_method_call_duration_seconds,
            'Method calls real duration',
            Transaction::BASE_LABELS.merge(BASE_LABELS),
            [0.01, 0.05, 0.1, 0.5, 1])
        end
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
        @real_time_seconds = 0
        @cpu_time = 0
        @call_count = 0
      end

      # Measures the real and CPU execution time of the supplied block.
      def measure
        start_real_seconds = System.monotonic_time
        start_cpu = System.cpu_time
        retval = yield

        real_time_seconds = System.monotonic_time - start_real_seconds
        cpu_time = System.cpu_time - start_cpu

        @real_time_seconds += real_time_seconds
        @cpu_time += cpu_time
        @call_count += 1

        if call_measurement_enabled? && above_threshold?
          self.class.call_duration_histogram.observe(@transaction.labels.merge(labels), real_time_seconds)
        end

        retval
      end

      def real_time_milliseconds
        (real_time_seconds * 1000.0).to_i
      end

      # Returns a Metric instance of the current method call.
      def to_metric
        Metric.new(
          Instrumentation.series,
          {
            duration: real_time_milliseconds,
            cpu_duration: cpu_time,
            call_count: call_count
          },
          method: @name
        )
      end

      # Returns true if the total runtime of this method exceeds the method call
      # threshold.
      def above_threshold?
        real_time_milliseconds >= Metrics.method_call_threshold
      end

      def call_measurement_enabled?
        Feature.get(:prometheus_metrics_method_instrumentation).enabled?
      end
    end
  end
end
