# frozen_string_literal: true

module Gitlab
  module CircuitBreaker
    class Notifier
      CircuitBreakerError = Class.new(RuntimeError)

      def notify(service_name, event)
        return unless event == 'failure'

        exception = CircuitBreakerError.new("Service #{service_name}: #{event}")
        exception.set_backtrace(Gitlab::BacktraceCleaner.clean_backtrace(caller))

        Gitlab::ErrorTracking.track_exception(exception)
      end

      def notify_warning(_service_name, _message)
        # no-op
      end

      def notify_run(_service_name, &_block)
        # This gets called by Circuitbox::CircuitBreaker#run to actually execute
        # the block passed.
        yield
      end
    end
  end
end
