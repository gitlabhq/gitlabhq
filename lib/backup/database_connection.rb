# frozen_string_literal: true

module Backup
  class DatabaseConnection
    attr_reader :database_configuration, :snapshot_id

    delegate :connection_name, to: :database_configuration
    delegate :connection, to: :@backup_model

    # Initializes a database connection
    #
    # @param [String] connection_name the key from `database.yml` for multi-database connection configuration
    def initialize(connection_name)
      @database_configuration = Backup::DatabaseConfiguration.new(connection_name)
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

    private

    delegate :activerecord_configuration, to: :database_configuration, private: true

    def configure_backup_model
      @backup_model.establish_connection(activerecord_configuration)

      Gitlab::Database::LoadBalancing::Setup.new(@backup_model).setup
    end

    # Creates a disposable model to be used to host the Backup connection only
    def backup_model
      klass_name = connection_name.camelize

      return "#{self.class.name}::#{klass_name}".constantize if self.class.const_defined?(klass_name.to_sym, false)

      self.class.const_set(klass_name, Class.new(ApplicationRecord))
    end

    def transaction_timeout_settings
      Gitlab::Database::TransactionTimeoutSettings.new(connection)
    end
  end
end
