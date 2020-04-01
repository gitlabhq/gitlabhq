# frozen_string_literal: true

require 'prometheus/pid_provider'

module Gitlab
  module Utils
    class Measuring
      def initialize(logger: Logger.new($stdout))
        @logger = logger
      end

      def with_measuring
        logger.info "Measuring enabled..."
        with_gc_stats do
          with_count_queries do
            with_measure_time do
              yield
            end
          end
        end

        logger.info "Memory usage: #{Gitlab::Metrics::System.memory_usage.to_f / 1024 / 1024} MiB"
        logger.info "Label: #{::Prometheus::PidProvider.worker_id}"
      end

      private

      attr_reader :logger

      def with_count_queries(&block)
        count = 0

        counter_f = ->(_name, _started, _finished, _unique_id, payload) {
          count += 1 unless payload[:name].in? %w[CACHE SCHEMA]
        }

        ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)

        logger.info "Number of sql calls: #{count}"
      end

      def with_gc_stats
        GC.start # perform a full mark-and-sweep
        stats_before = GC.stat
        yield
        stats_after = GC.stat
        stats_diff = stats_after.map do |key, after_value|
          before_value = stats_before[key]
          [key, before: before_value, after: after_value, diff: after_value - before_value]
        end.to_h
        logger.info "GC stats:"
        logger.info JSON.pretty_generate(stats_diff)
      end

      def with_measure_time
        timing = Benchmark.realtime do
          yield
        end

        logger.info "Time to finish: #{duration_in_numbers(timing)}"
      end

      def duration_in_numbers(duration_in_seconds)
        milliseconds = duration_in_seconds.in_milliseconds % 1.second.in_milliseconds
        seconds = duration_in_seconds % 1.minute
        minutes = (duration_in_seconds / 1.minute) % (1.hour / 1.minute)
        hours = duration_in_seconds / 1.hour

        if hours == 0
          "%02d:%02d:%03d" % [minutes, seconds, milliseconds]
        else
          "%02d:%02d:%02d:%03d" % [hours, minutes, seconds, milliseconds]
        end
      end
    end
  end
end
