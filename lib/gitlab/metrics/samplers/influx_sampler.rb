# frozen_string_literal: true

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
        def initialize(interval = ::Gitlab::Metrics.settings[:sample_interval])
          super(interval)
          @last_step = nil

          @metrics = []
        end

        def sample
          sample_memory_usage
          sample_file_descriptors

          flush
        ensure
          @metrics.clear
        end

        def flush
          ::Gitlab::Metrics.submit_metrics(@metrics.map(&:to_hash))
        end

        def sample_memory_usage
          add_metric('memory_usage', value: System.memory_usage)
        end

        def sample_file_descriptors
          add_metric('file_descriptors', value: System.file_descriptor_count)
        end

        def add_metric(series, values, tags = {})
          prefix = Gitlab::Runtime.sidekiq? ? 'sidekiq_' : 'rails_'

          @metrics << Metric.new("#{prefix}#{series}", values, tags)
        end
      end
    end
  end
end
