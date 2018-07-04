require 'prometheus/client/support/unicorn'

module Gitlab
  module Metrics
    module Samplers
      class RubySampler < BaseSampler
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
          {}
        end

        def init_metrics
          metrics = {}
          metrics[:sampler_duration] = Metrics.counter(with_prefix(:sampler, :duration_seconds_total), 'Sampler time', labels)
          metrics[:total_time] = Metrics.counter(with_prefix(:gc, :duration_seconds_total), 'Total GC time', labels)
          GC.stat.keys.each do |key|
            metrics[key] = Metrics.gauge(with_prefix(:gc_stat, key), to_doc_string(key), labels, :livesum)
          end

          metrics[:memory_usage] = Metrics.gauge(with_prefix(:memory, :bytes), 'Memory used', labels, :livesum)
          metrics[:file_descriptors] = Metrics.gauge(with_prefix(:file, :descriptors), 'File descriptors used', labels, :livesum)

          metrics
        end

        def sample
          start_time = System.monotonic_time

          metrics[:memory_usage].set(labels.merge(worker_label), System.memory_usage)
          metrics[:file_descriptors].set(labels.merge(worker_label), System.file_descriptor_count)

          sample_gc

          metrics[:sampler_duration].increment(labels, System.monotonic_time - start_time)
        ensure
          GC::Profiler.clear
        end

        private

        def sample_gc
          # Collect generic GC stats.
          GC.stat.each do |key, value|
            metrics[key].set(labels, value)
          end

          # Collect the GC time since last sample in float seconds.
          metrics[:total_time].increment(labels, GC::Profiler.total_time)
        end

        def worker_label
          return {} unless defined?(Unicorn::Worker)

          worker_no = ::Prometheus::Client::Support::Unicorn.worker_id

          if worker_no
            { worker: worker_no }
          else
            { worker: 'master' }
          end
        end
      end
    end
  end
end
