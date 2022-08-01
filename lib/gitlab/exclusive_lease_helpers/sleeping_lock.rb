# frozen_string_literal: true

module Gitlab
  module ExclusiveLeaseHelpers
    # Wrapper around ExclusiveLease that adds retry logic
    class SleepingLock
      delegate :cancel, to: :@lease
      MAX_ATTEMPTS = 65
      DEFAULT_ATTEMPTS = 10

      def initialize(key, timeout:, delay:)
        @lease = ::Gitlab::ExclusiveLease.new(key, timeout: timeout)
        @delay = delay
        @attempts = 0
      end

      def obtain(max_attempts = DEFAULT_ATTEMPTS)
        until held?
          raise FailedToObtainLockError, 'Failed to obtain a lock' if attempts >= [max_attempts, MAX_ATTEMPTS].min

          sleep(sleep_sec) unless first_attempt?
          try_obtain
        end
      end

      def retried?
        attempts > 1
      end

      private

      attr_reader :delay, :attempts

      def held?
        @uuid.present?
      end

      def try_obtain
        @uuid ||= @lease.try_obtain
        @attempts += 1
      end

      def first_attempt?
        attempts == 0
      end

      def sleep_sec
        delay.respond_to?(:call) ? delay.call(attempts) : delay
      end
    end
  end
end
