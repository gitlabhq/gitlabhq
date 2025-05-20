# frozen_string_literal: true

if defined?(Gitlab) && ActiveRecord.version.to_s != '7.1.5.1'
  raise "This patch is only needed in Rails 7.1.5.1 for https://github.com/rails/rails/issues/51780"
end

# rubocop:disable Lint/RescueException -- This is copied directly from Rails.
# rubocop:disable Lint/AmbiguousOperatorPrecedence -- This is a Rails patch.
# rubocop:disable Naming/RescuedExceptionsVariableName -- This is a Rails patch.
# rubocop:disable Style/NumericPredicate -- This is a Rails patch.
# rubocop:disable Cop/AvoidReturnFromBlocks -- This is a Rails patch.
# rubocop:disable Style/RescueStandardError -- This is a Rails patch.
module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      # Add the new method that wraps configure_connection with exception handling
      def attempt_configure_connection
        configure_connection
      rescue Exception # Need to handle things such as Timeout::ExitException
        disconnect!
        raise
      end

      # Disconnects from the database if already connected, and establishes a new
      # connection with the database. Implementors should define private #reconnect
      # instead.
      def reconnect!(restore_transactions: false)
        retries_available = connection_retries
        deadline = retry_deadline && Process.clock_gettime(Process::CLOCK_MONOTONIC) + retry_deadline

        @lock.synchronize do
          reconnect

          enable_lazy_transactions!
          @raw_connection_dirty = false
          @verified = true

          reset_transaction(restore: restore_transactions) do
            clear_cache!(new_connection: true)
            attempt_configure_connection
          end
        rescue => original_exception
          translated_exception = translate_exception_class(original_exception, nil, nil)
          retry_deadline_exceeded = deadline && deadline < Process.clock_gettime(Process::CLOCK_MONOTONIC)

          if !retry_deadline_exceeded && retries_available > 0
            retries_available -= 1

            if retryable_connection_error?(translated_exception)
              backoff(connection_retries - retries_available)
              retry
            end
          end

          @verified = false

          raise translated_exception
        end
      end

      # Reset the state of this connection, directing the DBMS to clear
      # transactions and other connection-related server-side state. Usually a
      # database-dependent operation.
      #
      # If a database driver or protocol does not support such a feature,
      # implementors may alias this to #reconnect!. Otherwise, implementors
      # should call super immediately after resetting the connection (and while
      # still holding @lock).
      def reset!
        clear_cache!(new_connection: true)
        reset_transaction
        attempt_configure_connection
      end

      # Checks whether the connection to the database is still active (i.e. not stale).
      # This is done under the hood by calling #active?. If the connection
      # is no longer active, then this method will reconnect to the database.
      def verify!
        unless active?
          @lock.synchronize do
            if @unconfigured_connection
              @raw_connection = @unconfigured_connection
              @unconfigured_connection = nil
              attempt_configure_connection
              @verified = true
              return
            end

            reconnect!(restore_transactions: true)
          end
        end

        @verified = true
      end
    end
  end
end
# rubocop:enable Lint/RescueException
# rubocop:enable Lint/AmbiguousOperatorPrecedence
# rubocop:enable Naming/RescuedExceptionsVariableName
# rubocop:enable Style/NumericPredicate
# rubocop:enable Cop/AvoidReturnFromBlocks
# rubocop:enable Style/RescueStandardError
