# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module LockRetriesHelpers
        # Executes the block with a retry mechanism that alters the +lock_timeout+ and +sleep_time+ between attempts.
        # The timings can be controlled via the +timing_configuration+ parameter.
        # If the lock was not acquired within the retry period, a last attempt is made without using +lock_timeout+.
        #
        # Note this helper uses subtransactions when run inside an already open transaction.
        #
        # ==== Examples
        #   # Invoking without parameters
        #   with_lock_retries do
        #     drop_table :my_table
        #   end
        #
        #   # Invoking with custom +timing_configuration+
        #   t = [
        #     [1.second, 1.second],
        #     [2.seconds, 2.seconds]
        #   ]
        #
        #   with_lock_retries(timing_configuration: t) do
        #     drop_table :my_table # this will be retried twice
        #   end
        #
        #   # Disabling the retries using an environment variable
        #   > export DISABLE_LOCK_RETRIES=true
        #
        #   with_lock_retries do
        #     drop_table :my_table # one invocation, it will not retry at all
        #   end
        #
        # ==== Parameters
        # * +timing_configuration+ - [[ActiveSupport::Duration, ActiveSupport::Duration], ...] lock timeout for the
        # block, sleep time before the next iteration, defaults to
        # `Gitlab::Database::WithLockRetries::DEFAULT_TIMING_CONFIGURATION`
        # * +logger+ - [Gitlab::JsonLogger]
        # * +env+ - [Hash] custom environment hash, see the example with `DISABLE_LOCK_RETRIES`
        def with_lock_retries(*args, **kwargs, &block)
          raise_on_exhaustion = !!kwargs.fetch(:raise_on_exhaustion, true)
          merged_args = {
            connection: connection,
            klass: self.class,
            logger: Gitlab::BackgroundMigration::Logger,
            allow_savepoints: true
          }.merge(kwargs.except(:raise_on_exhaustion))

          Gitlab::Database::WithLockRetries.new(**merged_args)
            .run(raise_on_exhaustion: raise_on_exhaustion, &block)
        end
      end
    end
  end
end
