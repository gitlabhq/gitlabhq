module Gitlab
  module Metrics
    # Class for tracking timing information about method calls
    class MethodCall
      attr_reader :real_time, :cpu_time, :call_count

      # name - The full name of the method (including namespace) such as
      #        `User#sign_in`.
      #
      def self.call_real_duration_histogram
        @call_real_duration_histogram ||= Gitlab::Metrics.histogram(:gitlab_method_call_real_duration_milliseconds,
                                                                    'Method calls real duration',
                                                                    {},
                                                                    [1, 2, 5, 10, 20, 50, 100, 1000])

      end

      def self.call_cpu_duration_histogram
        @call_duration_histogram ||= Gitlab::Metrics.histogram(:gitlab_method_call_cpu_duration_milliseconds,
                                                               'Method calls cpu duration',
                                                               {},
                                                               [1, 2, 5, 10, 20, 50, 100, 1000])
      end


      def initialize(name, tags = {})
        @name = name
        @real_time = 0
        @cpu_time = 0
        @call_count = 0
        @tags = tags
      end

      # Measures the real and CPU execution time of the supplied block.
      def measure
        start_real = System.monotonic_time
        start_cpu = System.cpu_time
        retval = yield

        @real_time += System.monotonic_time - start_real
        @cpu_time += System.cpu_time - start_cpu
        @call_count += 1

        if above_threshold?
          self.class.call_real_duration_histogram.observe(labels, @real_time)
          self.class.call_cpu_duration_histogram.observe(labels, @cpu_time)
        end

        retval
      end

      def labels
        @labels ||= @tags.merge(source_label).merge({ call_name: @name })
      end

      def source_label
        if Sidekiq.server?
          { source: 'sidekiq' }
        else
          { source: 'rails' }
        end
      end

      # Returns a Metric instance of the current method call.
      def to_metric
        Metric.new(
          Instrumentation.series,
          {
            duration: real_time,
            cpu_duration: cpu_time,
            call_count: call_count
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
