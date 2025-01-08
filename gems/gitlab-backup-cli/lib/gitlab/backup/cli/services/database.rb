# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Services
        class Database
          # @return [ActiveRecord::DatabaseConfigurations::HashConfig] database configuration
          attr_reader :configuration

          # @return [String] Snapshot ID from the database
          attr_reader :snapshot_id

          # Mapping of activerecord config keys to corresponding ENV variables
          DATABASE_ENV_VARIABLES = {
            username: 'PGUSER',
            host: 'PGHOST',
            port: 'PGPORT',
            password: 'PGPASSWORD',
            # SSL
            sslmode: 'PGSSLMODE',
            sslkey: 'PGSSLKEY',
            sslcert: 'PGSSLCERT',
            sslrootcert: 'PGSSLROOTCERT',
            sslcrl: 'PGSSLCRL',
            sslcompression: 'PGSSLCOMPRESSION'
          }.freeze

          # PostgreSQL timeout setting
          TIMEOUT_SETTING = 'idle_in_transaction_session_timeout'

          # @param [ActiveRecord::DatabaseConfigurations::HashConfig] configuration
          def initialize(configuration)
            @configuration = configuration
            @snapshot_id = nil
          end

          # Database connection params and credentials as PG ENV variables
          #
          # @return [Hash<String => String>]
          def pg_env_variables
            return @pg_env_variables if defined? @pg_env_variables

            @pg_env_variables = {}

            DATABASE_ENV_VARIABLES.each do |config_key, env_variable_name|
              value = connection_params[config_key].to_s.presence

              next unless value

              @pg_env_variables[env_variable_name] = value
            end

            @pg_env_variables
          end

          # Return the connection params from `database.yml`
          #
          # @return [Hash<Symbol => String>]
          def connection_params
            @connection_params ||= configuration.configuration_hash.dup
          end

          def export_snapshot!
            disable_timeouts!

            connection.begin_transaction(isolation: :repeatable_read)
            @snapshot_id = connection.select_value("SELECT pg_export_snapshot()")
          end

          def release_snapshot!
            return unless snapshot_id

            connection.rollback_transaction
            @snapshot_id = nil
          end

          def disable_timeouts!
            connection.execute("SET #{TIMEOUT_SETTING} = 0")
          end

          def restore_timeouts!
            connection.execute("RESET #{TIMEOUT_SETTING}")
          end

          private

          # Connection associated with current database
          #
          # @return [ActiveRecord::ConnectionAdapters::PostgreSQLAdapter] connection
          def connection
            @connection ||= connection_pool.connection
          end

          # @return [ActiveRecord::ConnectionAdapters::ConnectionPool] connection
          def connection_pool
            @connection_pool ||= connection_base_model.establish_connection(configuration)
          end

          # Creates a new class inheriting from ApplicationRecord to hold the connection pool
          #
          # It relies on the connection name to have a unique class that is ties to the connection params
          # This is necessary to allow for multiple connection pools to exist at the same time
          def connection_base_model
            klass_name = configuration.name.camelize

            if self.class.const_defined?(klass_name.to_sym, false)
              return "#{self.class.name}::#{klass_name}".constantize
            end

            self.class.const_set(klass_name, Class.new(ActiveRecord::Base))
          end
        end
      end
    end
  end
end
