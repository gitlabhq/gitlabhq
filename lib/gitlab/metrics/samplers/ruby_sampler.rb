module Gitlab
  module Metrics
    module Samplers
      class RubySampler < BaseSampler
        COUNTS = [:count, :minor_gc_count, :major_gc_count]

        def metrics
          @metrics ||= init_metrics
        end

        def with_prefix(prefix, name)
          "ruby_#{prefix}_#{name}".to_sym
        end

        def to_doc_string(name)
          name.to_s.humanize
        end

        def labels
          worker_label.merge(source_label)
        end

        def initialize(interval)
          super(interval)

          if Gitlab::Metrics.mri?
            require 'allocations'

            Allocations.start
          end
        end

        def init_metrics
          metrics = {}
          metrics[:samples_total] = Gitlab::Metrics.counter(with_prefix(:sampler, :total), 'Total count of samples')
          metrics[:total_time] = Gitlab::Metrics.gauge(with_prefix(:gc, :time_total), 'Total GC time', labels, :livesum)
          GC.stat.keys.each do |key|
            metrics[key] = Gitlab::Metrics.gauge(with_prefix(:gc, key), to_doc_string(key), labels, :livesum)
          end

          metrics[:objects_total] = Gitlab::Metrics.gauge(with_prefix(:objects, :total), 'Objects total', labels.merge(class: nil), :livesum)

          metrics
        end

        def sample

          metrics[:samples_total].increment(labels)
          sample_gc
          sample_objects
        rescue => ex
          puts ex

        end

        private

        def sample_gc
          metrics[:total_time].set(labels, GC::Profiler.total_time * 1000)

          GC.stat.each do |key, value|
            metrics[key].set(labels, value)
          end
        end

        def sample_objects
          ss_objects.each do |name, count|
            metrics[:objects_total].set(labels.merge(class: name), count)
          end
        end

        if Metrics.mri?
          def ss_objects
            sample = Allocations.to_hash
            counts = sample.each_with_object({}) do |(klass, count), hash|
              name = klass.name

              next unless name

              hash[name] = count
            end

            # Symbols aren't allocated so we'll need to add those manually.
            counts['Symbol'] = Symbol.all_symbols.length
            counts
          end
        else
          def ss_objects

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
      end
    end
  end
end