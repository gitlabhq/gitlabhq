# rubocop:disable Style/ClassVars

module Gitlab
  module Metrics
    # Class for tracking timing information about method calls
    class MethodCall
      @@measurement_enabled_cache = Concurrent::AtomicBoolean.new(false)
      @@measurement_enabled_cache_expires_at = Concurrent::AtomicReference.new(Time.now.to_i)
      MUTEX = Mutex.new
      BASE_LABELS = { module: nil, method: nil }.freeze
      attr_reader :real_time, :cpu_time, :call_count, :labels

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

      def self.measurement_enabled_cache_expires_at
        @@measurement_enabled_cache_expires_at
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

        if call_measurement_enabled? && above_threshold?
          self.class.call_duration_histogram.observe(@transaction.labels.merge(labels), real_time)
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

      def call_measurement_enabled?
        expires_at = @@measurement_enabled_cache_expires_at.value
        if expires_at < Time.now.to_i
          if @@measurement_enabled_cache_expires_at.compare_and_set(expires_at, 1.minute.from_now.to_i)
            @@measurement_enabled_cache.value = Feature.get(:prometheus_metrics_method_instrumentation).enabled?
          end
        end

        @@measurement_enabled_cache.value
      end
    end
  end
end
