# frozen_string_literal: true

module Gitlab
  module Database
    # This retry method behaves similar to WithLockRetries
    # except it does not wrap itself into a transaction scope.
    #
    # In our context, this is only useful if directly connected to
    # PostgreSQL. When going through pgbouncer, this method **won't work**
    # as it relies on using `SET` outside transactions (and hence can be
    # multiplexed across different connections).
    class WithLockRetriesOutsideTransaction < WithLockRetries
      private

      def run_block_with_lock_timeout
        execute("SET lock_timeout TO '#{current_lock_timeout_in_ms}ms'")

        log(message: 'Lock timeout is set', current_iteration: current_iteration, lock_timeout_in_ms: current_lock_timeout_in_ms)

        run_block

        log(message: 'Migration finished', current_iteration: current_iteration, lock_timeout_in_ms: current_lock_timeout_in_ms)
      end

      def run_block_without_lock_timeout
        log(message: "Couldn't acquire lock to perform the migration", current_iteration: current_iteration)
        log(message: "Executing without lock timeout", current_iteration: current_iteration)

        disable_lock_timeout

        run_block

        log(message: 'Migration finished', current_iteration: current_iteration)
      end

      def disable_lock_timeout
        execute("SET lock_timeout TO '0'")
      end
    end
  end
end
