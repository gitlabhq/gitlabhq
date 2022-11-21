# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      class Configuration
        class MonitorStack
          def initialize
            @monitors = []
          end

          def push(monitor_class, *args, **kwargs, &block)
            remove(monitor_class)
            @monitors.push(build_monitor_state(monitor_class, *args, **kwargs, &block))
          end

          def call_each
            @monitors.each do |monitor|
              yield monitor.call
            end
          end

          private

          def remove(monitor_class)
            @monitors.delete_if { |monitor| monitor.monitor_class == monitor_class }
          end

          def build_monitor_state(monitor_class, *args, max_strikes:, **kwargs, &block)
            monitor = build_monitor(monitor_class, *args, **kwargs, &block)

            Gitlab::Memory::Watchdog::MonitorState.new(monitor, max_strikes: max_strikes)
          end

          def build_monitor(monitor_class, *args, **kwargs, &block)
            monitor_class.new(*args, **kwargs, &block)
          end
        end

        DEFAULT_SLEEP_TIME_SECONDS = 60

        attr_writer :logger, :handler, :sleep_time_seconds, :write_heap_dumps

        def monitors
          @monitor_stack ||= MonitorStack.new
          yield @monitor_stack if block_given?
          @monitor_stack
        end

        def handler
          @handler ||= NullHandler.instance
        end

        def logger
          @logger ||= Gitlab::Logger.new($stdout)
        end

        # Used to control the frequency with which the watchdog will wake up and poll the GC.
        def sleep_time_seconds
          @sleep_time_seconds ||= DEFAULT_SLEEP_TIME_SECONDS
        end

        def write_heap_dumps?
          !!@write_heap_dumps
        end
      end
    end
  end
end
