# frozen_string_literal: true

module Gitlab
  module Checks
    class TimedLogger
      TimeoutError = Class.new(StandardError)

      attr_reader :start_time, :header, :log, :timeout

      def initialize(timeout:, start_time: Time.now, log: [], header: "")
        @start_time = start_time
        @timeout = timeout
        @header = header
        @log = log
      end

      # Adds trace of method being tracked with
      # the correspondent time it took to run it.
      # We make use of the start default argument
      # on unit tests related to this method
      #
      def log_timed(log_message, start = Time.now)
        check_timeout_reached

        timed = true

        yield

        append_message(log_message + time_suffix_message(start: start))
      rescue GRPC::DeadlineExceeded, TimeoutError
        args = { cancelled: true }
        args[:start] = start if timed

        append_message(log_message + time_suffix_message(**args))

        raise TimeoutError
      end

      def check_timeout_reached
        return unless time_expired?

        raise TimeoutError
      end

      def time_left
        (start_time + timeout.seconds) - Time.now
      end

      def full_message
        header + log.join("\n")
      end

      # We always want to append in-place on the log
      def append_message(message)
        log << message
      end

      private

      def time_expired?
        time_left <= 0
      end

      def time_suffix_message(cancelled: false, start: nil)
        return " (#{elapsed_time(start)}ms)" unless cancelled

        if start
          " (cancelled after #{elapsed_time(start)}ms)"
        else
          " (cancelled)"
        end
      end

      def elapsed_time(start)
        to_ms(Time.now - start)
      end

      def to_ms(elapsed)
        (elapsed.to_f * 1000).round(2)
      end
    end
  end
end
