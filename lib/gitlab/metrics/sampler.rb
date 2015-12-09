module Gitlab
  module Metrics
    # Class that sends certain metrics to InfluxDB at a specific interval.
    #
    # This class is used to gather statistics that can't be directly associated
    # with a transaction such as system memory usage, garbage collection
    # statistics, etc.
    class Sampler
      # interval - The sampling interval in seconds.
      def initialize(interval = 15)
        @interval = interval
        @metrics  = []

        @last_minor_gc = Delta.new(GC.stat[:minor_gc_count])
        @last_major_gc = Delta.new(GC.stat[:major_gc_count])
      end

      def start
        Thread.new do
          Thread.current.abort_on_exception = true

          loop do
            sleep(@interval)

            sample
          end
        end
      end

      def sample
        sample_memory_usage
        sample_file_descriptors
        sample_objects
        sample_gc

        flush
      ensure
        GC::Profiler.clear
        @metrics.clear
      end

      def flush
        MetricsWorker.perform_async(@metrics.map(&:to_hash))
      end

      def sample_memory_usage
        @metrics << Metric.new('memory_usage', value: System.memory_usage)
      end

      def sample_file_descriptors
        @metrics << Metric.
          new('file_descriptors', value: System.file_descriptor_count)
      end

      def sample_objects
        @metrics << Metric.new('object_counts', ObjectSpace.count_objects)
      end

      def sample_gc
        time  = GC::Profiler.total_time * 1000.0
        stats = GC.stat.merge(total_time: time)

        # We want the difference of GC runs compared to the last sample, not the
        # total amount since the process started.
        stats[:minor_gc_count] =
          @last_minor_gc.compared_with(stats[:minor_gc_count])

        stats[:major_gc_count] =
          @last_major_gc.compared_with(stats[:major_gc_count])

        stats[:count] = stats[:minor_gc_count] + stats[:major_gc_count]

        @metrics << Metric.new('gc_statistics', stats)
      end
    end
  end
end
