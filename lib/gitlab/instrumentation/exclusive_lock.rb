# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class ExclusiveLock
      EXCLUSIVE_LOCK_REQUESTED_COUNT = :exclusive_lock_requested_count
      EXCLUSIVE_LOCK_WAIT_DURATION = :exclusive_lock_wait_duration_s
      EXCLUSIVE_LOCK_HOLD_DURATION = :exclusive_lock_hold_duration_s

      class << self
        def requested_count
          ::Gitlab::SafeRequestStore[EXCLUSIVE_LOCK_REQUESTED_COUNT] || 0
        end

        def increment_requested_count
          return unless Gitlab::SafeRequestStore.active?

          ::Gitlab::SafeRequestStore[EXCLUSIVE_LOCK_REQUESTED_COUNT] ||= 0
          ::Gitlab::SafeRequestStore[EXCLUSIVE_LOCK_REQUESTED_COUNT] += 1
        end

        def wait_duration
          ::Gitlab::SafeRequestStore[EXCLUSIVE_LOCK_WAIT_DURATION] || 0
        end

        def add_wait_duration(duration)
          return unless Gitlab::SafeRequestStore.active?

          ::Gitlab::SafeRequestStore[EXCLUSIVE_LOCK_WAIT_DURATION] ||= 0
          ::Gitlab::SafeRequestStore[EXCLUSIVE_LOCK_WAIT_DURATION] += duration
        end

        def hold_duration
          ::Gitlab::SafeRequestStore[EXCLUSIVE_LOCK_HOLD_DURATION] || 0
        end

        def add_hold_duration(duration)
          return unless Gitlab::SafeRequestStore.active?

          ::Gitlab::SafeRequestStore[EXCLUSIVE_LOCK_HOLD_DURATION] ||= 0
          ::Gitlab::SafeRequestStore[EXCLUSIVE_LOCK_HOLD_DURATION] += duration
        end
      end

      def self.payload
        {
          EXCLUSIVE_LOCK_REQUESTED_COUNT => requested_count,
          EXCLUSIVE_LOCK_WAIT_DURATION => wait_duration,
          EXCLUSIVE_LOCK_HOLD_DURATION => hold_duration
        }
      end
    end
  end
end
