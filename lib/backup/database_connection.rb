# frozen_string_literal: true

module Backup
  class DatabaseConnection
    class CustomConfig < ApplicationRecord
      singleton_class.class_eval do
        undef_method :connection
        undef_method :load_balancer
        undef_method :sticking

        def connection
          retrieve_connection
        end
      end
    end

    attr_reader :database_configuration, :snapshot_id

    delegate :connection_name, to: :database_configuration
    delegate :connection, to: :@backup_model

    # Initializes a database connection
    #
    # @param [String] connection_name the key from `database.yml` for multi-database connection configuration
    # @param [Hash] custom_config optional custom database configuration hash (bypasses database.yml lookup)
    #   Example: {
    #     host: 'localhost', port: 5432, database: 'my_db', username: 'user', password: 'pass', adapter: 'postgresql'
    #   }
    def initialize(connection_name, custom_config: nil)
      @custom_config = custom_config
      @database_configuration = Backup::DatabaseConfiguration.new(connection_name, custom_config: custom_config)

      @backup_model = backup_model
      @snapshot_id = nil

      configure_backup_model
    end

    # Start a new transaction and run pg_export_snapshot()
    # Returns the snapshot identifier
    #
    # @return [String] snapshot identifier
    def export_snapshot!
      disable_timeouts!

      connection.begin_transaction(isolation: :repeatable_read)
      @snapshot_id = connection.select_value("SELECT pg_export_snapshot()")
    end

    # Rollback the transaction to release the effects of pg_export_snapshot()
    def release_snapshot!
      return unless snapshot_id

      connection.rollback_transaction
      @snapshot_id = nil
    end

    def disable_timeouts!
      transaction_timeout_settings.disable_timeouts
    end

    def restore_timeouts!
      transaction_timeout_settings.restore_timeouts
    end

    def tables
      backup_model.connection.execute(<<~SQL).values.flatten
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
      SQL
    end

    def functions
      backup_model.connection.execute(<<~SQL).values.flatten
        SELECT routine_name
        FROM information_schema.routines
        WHERE routine_type = 'FUNCTION'
        AND routine_schema='public'
        AND specific_catalog=current_database()
      SQL
    end

    private

    delegate :activerecord_configuration, to: :database_configuration, private: true

    def configure_backup_model
      @backup_model.establish_connection(activerecord_configuration)

      return if @custom_config

      # Only setup load balancing for connections configured in database.yml
      # Custom connections are not registered in Gitlab::Database.all_database_names
      # and will cause InvalidLoadBalancerNameError
      Gitlab::Database::LoadBalancing::Setup.new(@backup_model).setup
    end

    # Creates a disposable model to be used to host the Backup connection only
    def backup_model
      klass_name = connection_name.camelize

      return "#{self.class.name}::#{klass_name}".constantize if self.class.const_defined?(klass_name.to_sym, false)

      klass = if @custom_config
                Class.new(CustomConfig)
              else
                Class.new(ApplicationRecord)
              end

      self.class.const_set(klass_name, klass)
    end

    def transaction_timeout_settings
      Gitlab::Database::TransactionTimeoutSettings.new(connection)
    end
  end
end
