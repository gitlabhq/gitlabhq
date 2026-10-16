# frozen_string_literal: true

module Gitlab
  module Database
    module Session
      # Changes a PostgreSQL setting for the whole session, unlike Transaction::Settings, which
      # uses SET LOCAL and only lasts until the transaction ends.
      class Settings
        ALLOWED_CONFIGS = %w[
          statement_timeout
        ].freeze

        InvalidConfigError = Class.new(StandardError)
        TransactionOpenError = Class.new(StandardError)

        class << self
          # The SET lands on the primary, so the block is pinned to the primary too. Otherwise a
          # relation read inside the block could run on a replica that never saw the new value.
          def with(config_name, value, connection = ApplicationRecord.connection)
            check_allowed!(config_name)
            check_outside_transaction!(connection)

            use_primary(connection) do
              old_value = get(config_name, connection)

              set(config_name, value, connection)

              yield
            ensure
              set(config_name, old_value, connection) if old_value
            end
          end

          private

          # Only reachable through `with`: a SET without the restore would stay on the pooled
          # connection for every later request or job.
          def set(config_name, value, connection)
            connection.exec_query("SET #{config_name} = #{connection.quote(value)}")
          end

          def get(config_name, connection)
            connection.select_value("SHOW #{config_name}")
          end

          def check_allowed!(config_name)
            return if ALLOWED_CONFIGS.include?(config_name)

            raise InvalidConfigError, "Config #{config_name} is not allowed"
          end

          # A session-level SET survives the COMMIT, and a SET LOCAL value read back by SHOW
          # would be persisted on the restore.
          def check_outside_transaction!(connection)
            return unless connection.transaction_open?

            raise TransactionOpenError,
              "#{name} changes the whole session. Inside a transaction use Gitlab::Database::Transaction::Settings"
          end

          # A raw adapter connection has no load balancer and is already a single host.
          def use_primary(connection, &block)
            return yield unless connection.respond_to?(:load_balancer)

            Gitlab::Database::LoadBalancing::SessionMap.current(connection.load_balancer).use_primary(&block)
          end
        end
      end
    end
  end
end
