# frozen_string_literal: true

require 'prometheus/pid_provider'

module Gitlab
  module Utils
    class Measuring
      class << self
        attr_writer :logger

        def logger
          @logger ||= Logger.new($stdout)
        end
      end

      def initialize(base_log_data = {})
        @base_log_data = base_log_data
      end

      def with_measuring
        result = nil
        with_gc_stats do
          with_count_queries do
            with_measure_time do
              result = yield
            end
          end
        end

        log_info(
          gc_stats: gc_stats,
          time_to_finish: time_to_finish,
          number_of_sql_calls: sql_calls_count,
          memory_usage: "#{Gitlab::Metrics::System.memory_usage_rss.to_f / 1024 / 1024} MiB",
          label: ::Prometheus::PidProvider.worker_id
        )

        result
      end

      private

      attr_reader :gc_stats, :time_to_finish, :sql_calls_count, :base_log_data

      def with_count_queries(&block)
        @sql_calls_count = 0

        counter_f = ->(_name, _started, _finished, _unique_id, payload) {
          @sql_calls_count += 1 unless payload[:name].in? %w[CACHE SCHEMA]
        }

        ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
      end

      def with_gc_stats
        stats = ::Gitlab::Memory::Instrumentation.start_thread_memory_allocations
        yield
      ensure
        @gc_stats = ::Gitlab::Memory::Instrumentation.measure_thread_memory_allocations(stats)
      end

      def with_measure_time
        @time_to_finish = Benchmark.realtime do
          yield
        end
      end

      def log_info(details)
        details = base_log_data.merge(details)
        details = details.to_yaml if ActiveSupport::Logger.logger_outputs_to?(Measuring.logger, $stdout)
        Measuring.logger.info(details)
      end
    end
  end
end
