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
        with_gc_counter do
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

      def with_gc_counter
        gc_counts_before = GC.stat.select { |k, _v| k =~ /count/ }
        yield
        gc_counts_after = GC.stat.select { |k, _v| k =~ /count/ }
        stats = gc_counts_before.merge(gc_counts_after) { |_k, vb, va| va - vb }

        logger.info "Total GC count: #{stats[:count]}"
        logger.info "Minor GC count: #{stats[:minor_gc_count]}"
        logger.info "Major GC count: #{stats[:major_gc_count]}"
      end

      def with_measure_time
        timing = Benchmark.realtime do
          yield
        end

        logger.info "Time to finish: #{duration_in_numbers(timing)}"
      end

      def duration_in_numbers(duration_in_seconds)
        seconds = duration_in_seconds % 1.minute
        minutes = (duration_in_seconds / 1.minute) % (1.hour / 1.minute)
        hours = duration_in_seconds / 1.hour

        if hours == 0
          "%02d:%02d" % [minutes, seconds]
        else
          "%02d:%02d:%02d" % [hours, minutes, seconds]
        end
      end
    end
  end
end
