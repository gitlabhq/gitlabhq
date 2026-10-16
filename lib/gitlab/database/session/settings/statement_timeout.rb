# frozen_string_literal: true

module Gitlab
  module Database
    module Session
      class Settings
        # Changes statement_timeout for the session around a block and restores the previous value.
        # Callers that lift it past the transaction_timeout cap must lift that setting themselves.
        module StatementTimeout
          # @param timeout any value PostgreSQL accepts for statement_timeout, such as '2h',
          #   '500ms', milliseconds as an Integer, or 0 to disable the timeout
          def self.with(connection, timeout, &block)
            Settings.with('statement_timeout', timeout, connection, &block)
          end
        end
      end
    end
  end
end
