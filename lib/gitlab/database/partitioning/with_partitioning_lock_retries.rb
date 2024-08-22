# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      # Wrapper for Gitlab::Database::WithLockRetries.
      #
      # It sets lock_timeout to a max of 1 second per transaction. It doesn't holds the execution more than 27 seconds
      class WithPartitioningLockRetries < ::Gitlab::Database::WithLockRetries
        LOCK_RETRIES_TIMING_CONFIGURATION = [
          [0.1.seconds, 0.05.seconds],
          [0.1.seconds, 0.05.seconds],
          [0.2.seconds, 0.05.seconds],
          [0.3.seconds, 0.10.seconds],
          [0.4.seconds, 0.15.seconds],
          [0.5.seconds, 2.seconds],
          [0.5.seconds, 2.seconds],
          [0.5.seconds, 2.seconds],
          [0.5.seconds, 2.seconds],
          [1.second, 5.seconds]
        ].map(&:freeze).freeze

        def initialize(**args)
          args[:timing_configuration] = LOCK_RETRIES_TIMING_CONFIGURATION * 2

          super
        end
      end
    end
  end
end
