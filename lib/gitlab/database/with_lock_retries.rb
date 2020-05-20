# frozen_string_literal: true

module Gitlab
  module Database
    class WithLockRetries
      NULL_LOGGER = Gitlab::JsonLogger.new('/dev/null')

      # Each element of the array represents a retry iteration.
      # - DEFAULT_TIMING_CONFIGURATION.size provides the iteration count.
      # - First element: DB lock_timeout
      # - Second element: Sleep time after unsuccessful lock attempt (LockWaitTimeout error raised)
      # - Worst case, this configuration would retry for about 40 minutes.
      DEFAULT_TIMING_CONFIGURATION = [
        [0.1.seconds, 0.05.seconds], # short timings, lock_timeout: 100ms, sleep after LockWaitTimeout: 50ms
        [0.1.seconds, 0.05.seconds],
        [0.2.seconds, 0.05.seconds],
        [0.3.seconds, 0.10.seconds],
        [0.4.seconds, 0.15.seconds],
        [0.5.seconds, 2.seconds],
        [0.5.seconds, 2.seconds],
        [0.5.seconds, 2.seconds],
        [0.5.seconds, 2.seconds],
        [1.second, 5.seconds], # probably high traffic, increase timings
        [1.second, 1.minute],
        [0.1.seconds, 0.05.seconds],
        [0.1.seconds, 0.05.seconds],
        [0.2.seconds, 0.05.seconds],
        [0.3.seconds, 0.10.seconds],
        [0.4.seconds, 0.15.seconds],
        [0.5.seconds, 2.seconds],
        [0.5.seconds, 2.seconds],
        [0.5.seconds, 2.seconds],
        [3.seconds, 3.minutes], # probably high traffic or long locks, increase timings
        [0.1.seconds, 0.05.seconds],
        [0.1.seconds, 0.05.seconds],
        [0.5.seconds, 2.seconds],
        [0.5.seconds, 2.seconds],
        [5.seconds, 2.minutes],
        [0.5.seconds, 0.5.seconds],
        [0.5.seconds, 0.5.seconds],
        [7.seconds, 5.minutes],
        [0.5.seconds, 0.5.seconds],
        [0.5.seconds, 0.5.seconds],
        [7.seconds, 5.minutes],
        [0.5.seconds, 0.5.seconds],
        [0.5.seconds, 0.5.seconds],
        [7.seconds, 5.minutes],
        [0.1.seconds, 0.05.seconds],
        [0.1.seconds, 0.05.seconds],
        [0.5.seconds, 2.seconds],
        [10.seconds, 10.minutes],
        [0.1.seconds, 0.05.seconds],
        [0.5.seconds, 2.seconds],
        [10.seconds, 10.minutes]
      ].freeze

      def initialize(logger: NULL_LOGGER, timing_configuration: DEFAULT_TIMING_CONFIGURATION, klass: nil, env: ENV)
        @logger = logger
        @klass = klass
        @timing_configuration = timing_configuration
        @env = env
        @current_iteration = 1
        @log_params = { method: 'with_lock_retries', class: klass.to_s }
      end

      def run(&block)
        raise 'no block given' unless block_given?

        @block = block

        if lock_retries_disabled?
          log(message: 'DISABLE_LOCK_RETRIES environment variable is true, executing the block without retry')

          return run_block
        end

        begin
          run_block_with_transaction
        rescue ActiveRecord::LockWaitTimeout
          if retry_with_lock_timeout?
            disable_idle_in_transaction_timeout
            wait_until_next_retry
            reset_db_settings

            retry
          else
            reset_db_settings
            run_block_without_lock_timeout
          end

        ensure
          reset_db_settings
        end
      end

      private

      attr_reader :logger, :env, :block, :current_iteration, :log_params, :timing_configuration

      def run_block
        block.call
      end

      def run_block_with_transaction
        ActiveRecord::Base.transaction(requires_new: true) do
          execute("SET LOCAL lock_timeout TO '#{current_lock_timeout_in_ms}ms'")

          log(message: 'Lock timeout is set', current_iteration: current_iteration, lock_timeout_in_ms: current_lock_timeout_in_ms)

          run_block

          log(message: 'Migration finished', current_iteration: current_iteration, lock_timeout_in_ms: current_lock_timeout_in_ms)
        end
      end

      def retry_with_lock_timeout?
        current_iteration != retry_count
      end

      def wait_until_next_retry
        log(message: 'ActiveRecord::LockWaitTimeout error, retrying after sleep', current_iteration: current_iteration, sleep_time_in_seconds: current_sleep_time_in_seconds)

        sleep(current_sleep_time_in_seconds)

        @current_iteration += 1
      end

      def run_block_without_lock_timeout
        log(message: "Couldn't acquire lock to perform the migration", current_iteration: current_iteration)
        log(message: "Executing the migration without lock timeout", current_iteration: current_iteration)

        execute("SET LOCAL lock_timeout TO '0'")

        run_block

        log(message: 'Migration finished', current_iteration: current_iteration)
      end

      def lock_retries_disabled?
        Gitlab::Utils.to_boolean(env['DISABLE_LOCK_RETRIES'])
      end

      def log(params)
        logger.info(log_params.merge(params))
      end

      def execute(statement)
        ActiveRecord::Base.connection.execute(statement)
      end

      def retry_count
        timing_configuration.size
      end

      def current_lock_timeout_in_ms
        Integer(timing_configuration[current_iteration - 1][0].in_milliseconds)
      end

      def current_sleep_time_in_seconds
        timing_configuration[current_iteration - 1][1].to_f
      end

      def disable_idle_in_transaction_timeout
        execute("SET LOCAL idle_in_transaction_session_timeout TO '0'")
      end

      def reset_db_settings
        execute('RESET idle_in_transaction_session_timeout; RESET lock_timeout')
      end
    end
  end
end
