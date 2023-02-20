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
            @monitors.push(build_monitor_state(monitor_class, *args, **kwargs, &block))
          end

          def call_each
            @monitors.each do |monitor|
              yield monitor.call
            end
          end

          def empty?
            @monitors.empty?
          end

          private

          def build_monitor_state(monitor_class, *args, max_strikes:, monitor_name: nil, **kwargs, &block)
            monitor = build_monitor(monitor_class, *args, **kwargs, &block)
            monitor_name ||= monitor_class.name.demodulize.underscore

            Gitlab::Memory::Watchdog::MonitorState.new(monitor, max_strikes: max_strikes, monitor_name: monitor_name)
          end

          def build_monitor(monitor_class, *args, **kwargs, &block)
            monitor_class.new(*args, **kwargs, &block)
          end
        end

        DEFAULT_SLEEP_TIME_SECONDS = 60

        attr_writer :event_reporter, :handler, :sleep_time_seconds

        def monitors
          @monitor_stack ||= MonitorStack.new
          yield @monitor_stack if block_given?
          @monitor_stack
        end

        def handler
          @handler ||= Handlers::NullHandler.instance
        end

        def event_reporter
          @event_reporter ||= EventReporter.new
        end

        # Used to control the frequency with which the watchdog will wake up and poll the GC.
        def sleep_time_seconds
          @sleep_time_seconds ||= DEFAULT_SLEEP_TIME_SECONDS
        end
      end
    end
  end
end
