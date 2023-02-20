# frozen_string_literal: true

module Gitlab
  module Database
    class TransactionTimeoutSettings
      SETTING = 'idle_in_transaction_session_timeout'

      def initialize(connection)
        @connection = connection
      end

      def disable_timeouts
        @connection.execute("SET #{SETTING} = 0")
      end

      def restore_timeouts
        @connection.execute("RESET #{SETTING}")
      end
    end
  end
end
