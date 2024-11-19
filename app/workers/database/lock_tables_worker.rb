# frozen_string_literal: true

module Database
  class LockTablesWorker
    include ApplicationWorker

    TableShouldNotBeLocked = Class.new(StandardError)

    sidekiq_options retry: false
    feature_category :cell
    data_consistency :always
    idempotent!

    version 1

    def perform(database_name, tables)
      check_if_should_lock_database(database_name)

      connection = ::Gitlab::Database.database_base_models_with_gitlab_shared[database_name].connection
      check_if_should_lock_tables(tables, database_name, connection)

      performed_actions = tables.map do |table_name|
        lock_writes_manager(table_name, connection, database_name).lock_writes
      end

      log_extra_metadata_on_done(:performed_actions, performed_actions)
    end

    private

    def check_if_should_lock_database(database_name)
      raise TableShouldNotBeLocked, 'GitLab is not running in multiple database mode' unless
        Gitlab::Database.database_mode == Gitlab::Database::MODE_MULTIPLE_DATABASES

      raise TableShouldNotBeLocked, "database '#{database_name}' does not support locking writes on tables" unless
      ::Gitlab::Database.database_base_models_with_gitlab_shared.include?(database_name)
    end

    def check_if_should_lock_tables(tables, database_name, connection)
      tables.each do |table_name|
        unless should_lock_writes_on_table?(connection, database_name, table_name)
          raise TableShouldNotBeLocked, "table '#{table_name}' should not be locked on the database '#{database_name}'"
        end
      end
    end

    def should_lock_writes_on_table?(connection, database_name, table_name)
      db_info = Gitlab::Database.all_database_connections.fetch(database_name)
      table_schema = Gitlab::Database::GitlabSchema.table_schema!(table_name.to_s)

      Gitlab::Database.gitlab_schemas_for_connection(connection).exclude?(table_schema) &&
        db_info.lock_gitlab_schemas.include?(table_schema)
    end

    def lock_writes_manager(table_name, connection, database_name)
      Gitlab::Database::LockWritesManager.new(
        table_name: table_name,
        connection: connection,
        database_name: database_name,
        with_retries: !connection.transaction_open?,
        logger: nil,
        dry_run: false
      )
    end
  end
end
