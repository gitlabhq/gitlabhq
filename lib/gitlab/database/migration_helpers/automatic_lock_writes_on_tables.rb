# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module AutomaticLockWritesOnTables
        extend ActiveSupport::Concern

        included do
          class_attribute :skip_automatic_lock_on_writes
        end

        def exec_migration(connection, direction)
          db_config_name = Gitlab::Database.db_config_name(connection)
          db_info = Gitlab::Database.all_database_connections.fetch(db_config_name)
          return super if db_info.lock_gitlab_schemas.empty?
          return super if automatic_lock_on_writes_disabled?

          # This compares the tables only on the `public` schema. Partitions are not affected
          tables = connection.tables
          super
          new_tables = connection.tables - tables

          new_tables.each do |table_name|
            lock_writes_on_table(connection, table_name) if should_lock_writes_on_table?(db_info, table_name)
          end
        end

        private

        def automatic_lock_on_writes_disabled?
          # Feature flags are set on the main database, see tables features/feature_gates.
          # That is why we switch the ActiveRecord::Base.connection temporarily here back to the 'main' database
          # for the cases when the migration is targeting another database, like the 'ci' database.
          with_restored_connection_stack do |_|
            Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
              skip_automatic_lock_on_writes ||
                Gitlab::Utils.to_boolean(ENV['SKIP_AUTOMATIC_LOCK_ON_WRITES']) ||
                Feature.disabled?(:automatic_lock_writes_on_table, type: :ops)
            end
          end
        end

        def should_lock_writes_on_table?(db_info, table_name)
          # We skip locking writes on tables that are scheduled for deletion in a future migration
          return false if Gitlab::Database::GitlabSchema.deleted_tables_to_schema[table_name]

          table_schema = Gitlab::Database::GitlabSchema.table_schema!(table_name.to_s)

          # This takes into consideration which database mode is used.
          # In single-db and single-db-ci-connection the main database includes gitlab_ci tables,
          # so we don't lock them there.
          Gitlab::Database.gitlab_schemas_for_connection(connection).exclude?(table_schema) &&
            db_info.lock_gitlab_schemas.include?(table_schema)
        end

        # with_retries creates new a transaction. So we set it to false if the connection is
        # already has an open transaction, to avoid sub-transactions.
        def lock_writes_on_table(connection, table_name)
          database_name = Gitlab::Database.db_config_name(connection)
          LockWritesManager.new(
            table_name: table_name,
            connection: connection,
            database_name: database_name,
            with_retries: !connection.transaction_open?,
            logger: Logger.new($stdout)
          ).lock_writes
        end
      end
    end
  end
end
