# frozen_string_literal: true

module Gitlab
  module Memory
    # A background thread that monitors Ruby memory and calls
    # into a handler when the Ruby process violates defined limits
    # for an extended period of time.
    class Watchdog
      # This handler does nothing. It returns `false` to indicate to the
      # caller that the situation has not been dealt with so it will
      # receive calls repeatedly if fragmentation remains high.
      #
      # This is useful for "dress rehearsals" in production since it allows
      # us to observe how frequently the handler is invoked before taking action.
      class NullHandler
        include Singleton

        def call
          # NOP
          false
        end
      end

      # This handler sends SIGTERM and considers the situation handled.
      class TermProcessHandler
        def initialize(pid = $$)
          @pid = pid
        end

        def call
          Process.kill(:TERM, @pid)
          true
        end
      end

      # This handler invokes Puma's graceful termination handler, which takes
      # into account a configurable grace period during which a process may
      # remain unresponsive to a SIGTERM.
      class PumaHandler
        def initialize(puma_options = ::Puma.cli_config.options)
          @worker = ::Puma::Cluster::WorkerHandle.new(0, $$, 0, puma_options)
        end

        def call
          @worker.term
          true
        end
      end

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

          monitor if Feature.enabled?(:gitlab_memory_watchdog, type: :ops)
        end

        event_reporter.stopped(log_labels(memwd_reason: @reason).compact)
      end

      def stop(reason: nil)
        @reason = reason
        @alive = false
      end

      private

      attr_reader :configuration

      delegate :event_reporter, :monitors, :sleep_time_seconds, to: :configuration

      def monitor
        if monitors.empty?
          stop(reason: 'monitors are not configured')
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

        stop(reason: 'successfully handled') if handler.call
      end

      def handler
        # This allows us to keep the watchdog running but turn it into "friendly mode" where
        # all that happens is we collect logs and Prometheus events for fragmentation violations.
        return NullHandler.instance unless Feature.enabled?(:enforce_memory_watchdog, type: :ops)

        configuration.handler
      end

      def log_labels(extra = {})
        extra.merge(
          memwd_handler_class: handler.class.name,
          memwd_sleep_time_s: sleep_time_seconds
        )
      end
    end
  end
end
