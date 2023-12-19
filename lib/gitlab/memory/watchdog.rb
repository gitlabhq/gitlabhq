# frozen_string_literal: true

module Gitlab
  module Memory
    # A background thread that monitors Ruby memory and calls
    # into a handler when the Ruby process violates defined limits
    # for an extended period of time.
    class Watchdog
      def initialize
        @configuration = Configuration.new
        @alive = true
      end

      ##
      # Configuration for Watchdog, see Gitlab::Memory::Watchdog::Configurator
      # for examples.
      def configure
        yield configuration
      end

      def call
        event_reporter.started(log_labels)

        while @alive
          sleep(sleep_time_seconds)

          monitor
        end

        event_reporter.stopped(log_labels(memwd_reason: @stop_reason).compact)
      end

      def stop
        stop_working(reason: 'background task stopped')
        handler.stop if handler.respond_to?(:stop)
      end

      private

      attr_reader :configuration

      delegate :event_reporter, :monitors, :sleep_time_seconds, to: :configuration

      def monitor
        if monitors.empty?
          stop_working(reason: 'monitors are not configured')
          return
        end

        monitors.call_each do |result|
          break unless @alive

          next unless result.threshold_violated?

          event_reporter.threshold_violated(result.monitor_name)

          next unless result.strikes_exceeded?

          strike_exceeded_callback(result.monitor_name, result.payload)
        end
      end

      def strike_exceeded_callback(monitor_name, monitor_payload)
        event_reporter.strikes_exceeded(monitor_name, log_labels(monitor_payload))

        Gitlab::Memory::Reports::HeapDump.enqueue!

        stop_working(reason: 'successfully handled') if handler.call
      end

      def handler
        configuration.handler
      end

      def log_labels(extra = {})
        extra.merge(
          memwd_handler_class: handler.class.name,
          memwd_sleep_time_s: sleep_time_seconds
        )
      end

      def stop_working(reason:)
        return unless @alive

        @stop_reason = reason
        @alive = false
      end
    end
  end
end
