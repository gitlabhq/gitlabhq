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

        def initialize(interval)
          super(interval)

          if Metrics.mri?
            require 'allocations'

            Allocations.start
          end
        end

        def init_metrics
          metrics = {}
          metrics[:sampler_duration] = Metrics.histogram(with_prefix(:sampler_duration, :seconds), 'Sampler time', { worker: nil })
          metrics[:total_time] = Metrics.gauge(with_prefix(:gc, :time_total), 'Total GC time', labels, :livesum)
          GC.stat.keys.each do |key|
            metrics[key] = Metrics.gauge(with_prefix(:gc, key), to_doc_string(key), labels, :livesum)
          end

          metrics[:objects_total] = Metrics.gauge(with_prefix(:objects, :total), 'Objects total', labels.merge(class: nil), :livesum)
          metrics[:memory_usage] = Metrics.gauge(with_prefix(:memory, :usage_total), 'Memory used total', labels, :livesum)
          metrics[:file_descriptors] = Metrics.gauge(with_prefix(:file, :descriptors_total), 'File descriptors total', labels, :livesum)

          metrics
        end

        def sample
          start_time = System.monotonic_time
          sample_gc

          metrics[:memory_usage].set(labels, System.memory_usage)
          metrics[:file_descriptors].set(labels, System.file_descriptor_count)

          metrics[:sampler_duration].observe(labels.merge(worker_label), System.monotonic_time - start_time)
        ensure
          GC::Profiler.clear
        end

        private

        def sample_gc
          metrics[:total_time].set(labels, GC::Profiler.total_time * 1000)

          GC.stat.each do |key, value|
            metrics[key].set(labels, value)
          end
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
