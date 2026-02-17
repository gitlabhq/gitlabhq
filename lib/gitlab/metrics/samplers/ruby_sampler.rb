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

          init_yjit_metrics(metrics)

          metrics
        end

        def sample
          start_time = System.monotonic_time

          metrics[:file_descriptors].set(labels, System.file_descriptor_count)
          metrics[:process_cpu_seconds_total].set(labels, ::Gitlab::Metrics::System.cpu_time)
          metrics[:process_max_fds].set(labels, ::Gitlab::Metrics::System.max_open_file_descriptors)
          set_memory_usage_metrics
          sample_gc
          sample_yjit_metrics

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

        def yjit_enabled?
          defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
        end

        # rubocop:disable Metrics/AbcSize -- There are many metrics here to capture
        def init_yjit_metrics(metrics)
          metrics[:yjit_enabled] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :enabled), 'YJIT enabled', labels)
          metrics[:yjit_inline_code_size_bytes] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :inline_code_size_bytes), 'YJIT inline code size', labels)
          metrics[:yjit_outlined_code_size_bytes] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :outlined_code_size_bytes), 'YJIT outlined code size', labels)
          metrics[:yjit_freed_page_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :freed_page_count), 'YJIT freed page count', labels)
          metrics[:yjit_freed_code_size_bytes] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :freed_code_size_bytes), 'YJIT freed code size', labels)
          metrics[:yjit_live_page_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :live_page_count), 'YJIT live page count', labels)
          metrics[:yjit_code_region_size_bytes] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :code_region_size_bytes), 'YJIT code region size', labels)
          metrics[:yjit_alloc_size_bytes] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :alloc_size_bytes), 'YJIT allocation size', labels)
          metrics[:yjit_vm_insns_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :vm_insns_count), 'YJIT VM instructions count', labels)
          metrics[:yjit_live_iseq_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :live_iseq_count), 'YJIT live ISEQ count', labels)
          metrics[:yjit_code_gc_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :code_gc_count), 'YJIT code GC count', labels)
          metrics[:yjit_compiled_iseq_entry] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :compiled_iseq_entry), 'YJIT compiled ISEQ entry', labels)
          metrics[:yjit_cold_iseq_entry] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :cold_iseq_entry), 'YJIT cold ISEQ entry', labels)
          metrics[:yjit_compiled_iseq_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :compiled_iseq_count), 'YJIT compiled ISEQ count', labels)
          metrics[:yjit_compiled_blockid_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :compiled_blockid_count), 'YJIT compiled block ID count', labels)
          metrics[:yjit_compiled_block_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :compiled_block_count), 'YJIT compiled block count', labels)
          metrics[:yjit_compiled_branch_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :compiled_branch_count), 'YJIT compiled branch count', labels)
          metrics[:yjit_compile_time_seconds] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :compile_time_seconds), 'YJIT compile time', labels)
          metrics[:yjit_object_shape_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :object_shape_count), 'YJIT object shape count', labels)
          metrics[:yjit_hit_ratio] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :hit_ratio), 'YJIT hit ratio', labels)
          metrics[:yjit_side_exit_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :side_exit_count), 'YJIT side exit count', labels)
          metrics[:yjit_insns_count] = ::Gitlab::Metrics.gauge(metric_name(:yjit, :insns_count), 'YJIT instructions count', labels)
        end

        def sample_yjit_metrics
          metrics[:yjit_enabled].set(labels, yjit_enabled? ? 1 : 0)

          return unless yjit_enabled?

          stats = RubyVM::YJIT.runtime_stats

          metrics[:yjit_inline_code_size_bytes].set(labels, stats[:inline_code_size])
          metrics[:yjit_outlined_code_size_bytes].set(labels, stats[:outlined_code_size])
          metrics[:yjit_freed_page_count].set(labels, stats[:freed_page_count])
          metrics[:yjit_freed_code_size_bytes].set(labels, stats[:freed_code_size])
          metrics[:yjit_live_page_count].set(labels, stats[:live_page_count])
          metrics[:yjit_code_region_size_bytes].set(labels, stats[:code_region_size])
          metrics[:yjit_alloc_size_bytes].set(labels, stats[:yjit_alloc_size])
          metrics[:yjit_vm_insns_count].set(labels, stats[:vm_insns_count])
          metrics[:yjit_live_iseq_count].set(labels, stats[:live_iseq_count])
          metrics[:yjit_code_gc_count].set(labels, stats[:code_gc_count])
          metrics[:yjit_compiled_iseq_entry].set(labels, stats[:compiled_iseq_entry])
          metrics[:yjit_cold_iseq_entry].set(labels, stats[:cold_iseq_entry])
          metrics[:yjit_compiled_iseq_count].set(labels, stats[:compiled_iseq_count])
          metrics[:yjit_compiled_blockid_count].set(labels, stats[:compiled_blockid_count])
          metrics[:yjit_compiled_block_count].set(labels, stats[:compiled_block_count])
          metrics[:yjit_compiled_branch_count].set(labels, stats[:compiled_branch_count])
          metrics[:yjit_compile_time_seconds].set(labels, stats[:compile_time_ns].to_f / 1_000_000_000)
          metrics[:yjit_object_shape_count].set(labels, stats[:object_shape_count])
          metrics[:yjit_hit_ratio].set(labels, stats[:ratio_in_yjit]) if stats.key?(:ratio_in_yjit)
          metrics[:yjit_side_exit_count].set(labels, stats[:side_exit_count]) if stats.key?(:side_exit_count)
          metrics[:yjit_insns_count].set(labels, stats[:yjit_insns_count]) if stats.key?(:yjit_insns_count)
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
