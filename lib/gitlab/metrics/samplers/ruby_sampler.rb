# frozen_string_literal: true

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
          metrics = {
            file_descriptors:               ::Gitlab::Metrics.gauge(with_prefix(:file, :descriptors), 'File descriptors used', labels, :livesum),
            memory_bytes:                   ::Gitlab::Metrics.gauge(with_prefix(:memory, :bytes), 'Memory used', labels, :livesum),
            process_cpu_seconds_total:      ::Gitlab::Metrics.gauge(with_prefix(:process, :cpu_seconds_total), 'Process CPU seconds total'),
            process_max_fds:                ::Gitlab::Metrics.gauge(with_prefix(:process, :max_fds), 'Process max fds'),
            process_resident_memory_bytes:  ::Gitlab::Metrics.gauge(with_prefix(:process, :resident_memory_bytes), 'Memory used', labels, :livesum),
            process_start_time_seconds:     ::Gitlab::Metrics.gauge(with_prefix(:process, :start_time_seconds), 'Process start time seconds'),
            sampler_duration:               ::Gitlab::Metrics.counter(with_prefix(:sampler, :duration_seconds_total), 'Sampler time', labels),
            total_time:                     ::Gitlab::Metrics.counter(with_prefix(:gc, :duration_seconds_total), 'Total GC time', labels)
          }

          GC.stat.keys.each do |key|
            metrics[key] = ::Gitlab::Metrics.gauge(with_prefix(:gc_stat, key), to_doc_string(key), labels, :livesum)
          end

          metrics
        end

        def sample
          start_time = System.monotonic_time

          metrics[:file_descriptors].set(labels.merge(worker_label), System.file_descriptor_count)
          metrics[:process_cpu_seconds_total].set(labels.merge(worker_label), ::Gitlab::Metrics::System.cpu_time)
          metrics[:process_max_fds].set(labels.merge(worker_label), ::Gitlab::Metrics::System.max_open_file_descriptors)
          metrics[:process_start_time_seconds].set(labels.merge(worker_label), ::Gitlab::Metrics::System.process_start_time)
          set_memory_usage_metrics
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

        def set_memory_usage_metrics
          memory_usage = System.memory_usage
          memory_labels = labels.merge(worker_label)

          metrics[:memory_bytes].set(memory_labels, memory_usage)
          metrics[:process_resident_memory_bytes].set(memory_labels, memory_usage)
        end

        def worker_label
          return { worker: 'sidekiq' } if Sidekiq.server?
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
