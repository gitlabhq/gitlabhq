# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class RubySampler < BaseSampler
        DEFAULT_SAMPLING_INTERVAL_SECONDS = 60
        GC_REPORT_BUCKETS = [0.01, 0.05, 0.1, 0.2, 0.3, 0.5, 1].freeze

        def initialize(prefix: nil, **options)
          @prefix = prefix

          GC::Profiler.clear

          metrics[:process_start_time_seconds].set(labels, Time.now.to_i)

          super(**options)
        end

        def metrics
          @metrics ||= init_metrics
        end

        def to_doc_string(name)
          name.to_s.humanize
        end

        def labels
          {}
        end

        def init_metrics
          metrics = {
            file_descriptors: ::Gitlab::Metrics.gauge(metric_name(:file, :descriptors), 'File descriptors used', labels),
            process_cpu_seconds_total: ::Gitlab::Metrics.gauge(metric_name(:process, :cpu_seconds_total), 'Process CPU seconds total'),
            process_max_fds: ::Gitlab::Metrics.gauge(metric_name(:process, :max_fds), 'Process max fds'),
            process_resident_memory_bytes: ::Gitlab::Metrics.gauge(metric_name(:process, :resident_memory_bytes), 'Memory used (RSS)', labels),
            process_resident_anon_memory_bytes: ::Gitlab::Metrics.gauge(metric_name(:process, :resident_anon_memory_bytes), 'Anonymous memory used (RSS)', labels),
            process_resident_file_memory_bytes: ::Gitlab::Metrics.gauge(metric_name(:process, :resident_file_memory_bytes), 'File backed memory used (RSS)', labels),
            process_unique_memory_bytes: ::Gitlab::Metrics.gauge(metric_name(:process, :unique_memory_bytes), 'Memory used (USS)', labels),
            process_proportional_memory_bytes: ::Gitlab::Metrics.gauge(metric_name(:process, :proportional_memory_bytes), 'Memory used (PSS)', labels),
            process_start_time_seconds: ::Gitlab::Metrics.gauge(metric_name(:process, :start_time_seconds), 'Process start time seconds'),
            sampler_duration: ::Gitlab::Metrics.counter(metric_name(:sampler, :duration_seconds_total), 'Sampler time', labels),
            gc_duration_seconds: ::Gitlab::Metrics.histogram(metric_name(:gc, :duration_seconds), 'GC time', labels, GC_REPORT_BUCKETS),
            heap_fragmentation: ::Gitlab::Metrics.gauge(metric_name(:gc_stat_ext, :heap_fragmentation), 'Ruby heap fragmentation', labels)
          }

          GC.stat.keys.each do |key|
            metrics[key] = ::Gitlab::Metrics.gauge(metric_name(:gc_stat, key), to_doc_string(key), labels)
          end

          metrics
        end

        def sample
          start_time = System.monotonic_time

          metrics[:file_descriptors].set(labels, System.file_descriptor_count)
          metrics[:process_cpu_seconds_total].set(labels, ::Gitlab::Metrics::System.cpu_time)
          metrics[:process_max_fds].set(labels, ::Gitlab::Metrics::System.max_open_file_descriptors)
          set_memory_usage_metrics
          sample_gc

          metrics[:sampler_duration].increment(labels, System.monotonic_time - start_time)
        end

        private

        def metric_name(group, metric)
          name = "ruby_#{group}_#{metric}"
          name = "#{@prefix}_#{name}" if @prefix.present?
          name.to_sym
        end

        def sample_gc
          # Observe all GC samples
          sample_gc_reports.each do |report|
            metrics[:gc_duration_seconds].observe(labels, report[:GC_TIME])
          end

          # Collect generic GC stats
          GC.stat.then do |gc_stat|
            gc_stat.each do |key, value|
              metrics[key].set(labels, value)
            end

            # Collect custom GC stats
            metrics[:heap_fragmentation].set(labels, Memory.gc_heap_fragmentation(gc_stat))
          end
        end

        def sample_gc_reports
          GC::Profiler.enable
          GC::Profiler.raw_data
        ensure
          GC::Profiler.clear
        end

        def set_memory_usage_metrics
          rss = System.memory_usage_rss
          metrics[:process_resident_memory_bytes].set(labels, rss[:total])
          metrics[:process_resident_anon_memory_bytes].set(labels, rss[:anon])
          metrics[:process_resident_file_memory_bytes].set(labels, rss[:file])

          if Gitlab::Utils.to_boolean(ENV['enable_memory_uss_pss'] || '1')
            memory_uss_pss = System.memory_usage_uss_pss
            metrics[:process_unique_memory_bytes].set(labels, memory_uss_pss[:uss])
            metrics[:process_proportional_memory_bytes].set(labels, memory_uss_pss[:pss])
          end
        end
      end
    end
  end
end
