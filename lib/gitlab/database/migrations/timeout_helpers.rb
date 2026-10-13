# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module TimeoutHelpers
        # Long-running migrations may take more than the timeout allowed by
        # the database. Disable the session's statement timeout to ensure
        # migrations don't get killed prematurely. On PostgreSQL 17+ the
        # transaction timeout is disabled for the same scope.
        #
        # There are two possible ways to disable the statement timeout:
        #
        # - Per transaction (this is the preferred and default mode)
        # - Per connection (requires a cleanup after the execution)
        #
        # When using a per connection disable statement, code must be inside
        # a block so we can automatically execute `RESET statement_timeout` after block finishes
        # otherwise the statement will still be disabled until connection is dropped
        # or `RESET statement_timeout` is executed
        def disable_statement_timeout
          if block_given?
            if statement_timeout_disabled?
              # Don't touch statement_timeout if it is already disabled
              # Allows for nested calls of disable_statement_timeout without
              # resetting the timeout too early (before the outer call ends)
              with_transaction_timeout_disabled { yield }
            else
              begin
                execute('SET statement_timeout TO 0')

                with_transaction_timeout_disabled { yield }
              ensure
                execute('RESET statement_timeout')
              end
            end
          else
            unless transaction_open?
              raise <<~ERROR
                Cannot call disable_statement_timeout() without a transaction open or outside of a transaction block.
                If you don't want to use a transaction wrap your code in a block call:

                disable_statement_timeout { # code that requires disabled statement here }

                This will make sure statement_timeout is disabled before and reset after the block execution is finished.
              ERROR
            end

            execute('SET LOCAL statement_timeout TO 0')
            Gitlab::Database::TransactionTimeout.disable(connection, local: true)
          end
        end

        private

        # Same nesting rule as statement_timeout: never reset an exemption an outer scope established.
        def with_transaction_timeout_disabled
          return yield if transaction_timeout_disabled?

          begin
            Gitlab::Database::TransactionTimeout.disable(connection)

            yield
          ensure
            Gitlab::Database::TransactionTimeout.reset(connection)
          end
        end

        def statement_timeout_disabled?
          # This is a string of the form "100ms" or "0" when disabled
          connection.select_value('SHOW statement_timeout') == "0"
        end

        def transaction_timeout_disabled?
          return true unless Gitlab::Database::TransactionTimeout.supported?(connection)

          connection.select_value('SHOW transaction_timeout') == "0"
        end
      end
    end
  end
end
