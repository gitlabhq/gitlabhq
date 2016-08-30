module Gitlab
  module Metrics
    # Class for tracking timing information about method calls
    class MethodCall
      attr_reader :real_time, :cpu_time, :call_count

      # name - The full name of the method (including namespace) such as
      #        `User#sign_in`.
      #
      # series - The series to use for storing the data.
      def initialize(name, series)
        @name = name
        @series = series
        @real_time = 0
        @cpu_time = 0
        @call_count = 0
      end

      # Measures the real and CPU execution time of the supplied block.
      def measure
        start_real = System.monotonic_time
        start_cpu = System.cpu_time
        retval = yield

        @real_time += System.monotonic_time - start_real
        @cpu_time += System.cpu_time - start_cpu
        @call_count += 1

        retval
      end

      # Returns a Metric instance of the current method call.
      def to_metric
        Metric.new(
          @series,
          {
            duration:     real_time,
            cpu_duration: cpu_time,
            call_count:   call_count
          },
          method: @name
        )
      end

      # Returns true if the total runtime of this method exceeds the method call
      # threshold.
      def above_threshold?
        real_time >= Metrics.method_call_threshold
      end
    end
  end
end
