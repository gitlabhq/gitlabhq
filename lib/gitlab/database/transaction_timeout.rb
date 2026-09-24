# frozen_string_literal: true

module Gitlab
  module Database
    # GitLab.com caps every transaction with a cluster-wide `transaction_timeout` (PostgreSQL 17+), so
    # code that lifts `statement_timeout` or `idle_in_transaction_session_timeout` must lift this too.
    # See https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/work_items/25884
    module TransactionTimeout
      # The setting does not exist before PostgreSQL 17, where SET would raise an error.
      MINIMUM_POSTGRES_VERSION = 17_00_00

      def self.supported?(connection)
        connection.database_version >= MINIMUM_POSTGRES_VERSION
      end

      # Mirror the statement_timeout a caller raised, so the transaction stays bounded by the same value.
      def self.set(connection, timeout, local: false)
        return unless supported?(connection)

        # Inside a transaction the timer is already running; only a zero disarms it, raising the value alone
        # leaves the old deadline in place even though SHOW reports the new one.
        connection.execute('SET LOCAL transaction_timeout TO 0') if timeout.to_i > 0 && connection.transaction_open?
        connection.execute("SET #{'LOCAL ' if local}transaction_timeout TO '#{timeout.to_i}s'")
      end

      def self.disable(connection, local: false)
        set(connection, 0, local: local)
      end

      def self.reset(connection)
        return unless supported?(connection)

        connection.execute('RESET transaction_timeout')
      end
    end
  end
end
