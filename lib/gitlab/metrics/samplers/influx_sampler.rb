module Gitlab
  module Metrics
    module Samplers
      # Class that sends certain metrics to InfluxDB at a specific interval.
      #
      # This class is used to gather statistics that can't be directly associated
      # with a transaction such as system memory usage, garbage collection
      # statistics, etc.
      class InfluxSampler < BaseSampler
        # interval - The sampling interval in seconds.
        def initialize(interval = Metrics.settings[:sample_interval])
          super(interval)
          @last_step = nil

          @metrics = []

          @last_minor_gc = Delta.new(GC.stat[:minor_gc_count])
          @last_major_gc = Delta.new(GC.stat[:major_gc_count])

          if Gitlab::Metrics.mri?
            require 'allocations'

            Allocations.start
          end
        end

        def sample
          sample_memory_usage
          sample_file_descriptors
          sample_gc

          flush
        ensure
          GC::Profiler.clear
          @metrics.clear
        end

        def flush
          Metrics.submit_metrics(@metrics.map(&:to_hash))
        end

        def sample_memory_usage
          add_metric('memory_usage', value: System.memory_usage)
        end

        def sample_file_descriptors
          add_metric('file_descriptors', value: System.file_descriptor_count)
        end

        def sample_gc
          time = GC::Profiler.total_time * 1000.0
          stats = GC.stat.merge(total_time: time)

          # We want the difference of GC runs compared to the last sample, not the
          # total amount since the process started.
          stats[:minor_gc_count] =
            @last_minor_gc.compared_with(stats[:minor_gc_count])

          stats[:major_gc_count] =
            @last_major_gc.compared_with(stats[:major_gc_count])

          stats[:count] = stats[:minor_gc_count] + stats[:major_gc_count]

          add_metric('gc_statistics', stats)
        end

        def add_metric(series, values, tags = {})
          prefix = sidekiq? ? 'sidekiq_' : 'rails_'

          @metrics << Metric.new("#{prefix}#{series}", values, tags)
        end

        def sidekiq?
          Sidekiq.server?
        end
      end
    end
  end
end
