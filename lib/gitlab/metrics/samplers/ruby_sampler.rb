module Gitlab
  module Metrics
    module Samplers
      class RubySampler < BaseSampler

        COUNTS = [:count, :minor_gc_count, :major_gc_count]

        def metrics
          @metrics ||= init_metrics
        end

        def with_prefix(name)
          "ruby_gc_#{name}".to_sym
        end

        def to_doc_string(name)
          name.to_s.humanize
        end

        def labels
          worker_label.merge(source_label)
        end

        def initialize(interval)
          super(interval)
          GC::Profiler.enable
          Rails.logger.info("123")

          init_metrics
        end

        def init_metrics
          metrics = {}
          metrics[:total_time] = Gitlab::Metrics.gauge(with_prefix(:total_time), to_doc_string(:total_time), labels, :livesum)
          GC.stat.keys.each do |key|
            metrics[key] = Gitlab::Metrics.gauge(with_prefix(key), to_doc_string(key), labels, :livesum)
          end
          metrics
        end

        def sample
          metrics[:total_time].set(labels, GC::Profiler.total_time * 1000)

          GC.stat.each do |key, value|
            metrics[key].set(labels, value)
          end
        end

        def source_label
          if Sidekiq.server?
            { source: 'sidekiq' }
          else
            { source: 'rails' }
          end
        end

        def worker_label
          return {} unless defined?(Unicorn::Worker)
          worker = if defined?(Unicorn::Worker)
                     ObjectSpace.each_object(Unicorn::Worker)&.first
                   end
          if worker
            { unicorn: worker.nr }
          else
            { unicorn: 'master' }
          end
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
      end
    end
  end
end