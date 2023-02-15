# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncForeignKeys
      module MigrationHelpers
        # Prepares a foreign key for asynchronous validation.
        #
        # Stores the FK information in the postgres_async_foreign_key_validations
        # table to be executed later.
        #
        def prepare_async_foreign_key_validation(table_name, column_name = nil, name: nil)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

          return unless async_fk_validation_available?

          fk_name = name || concurrent_foreign_key_name(table_name, column_name)

          unless foreign_key_exists?(table_name, name: fk_name)
            raise missing_schema_object_message(table_name, "foreign key", fk_name)
          end

          async_validation = PostgresAsyncForeignKeyValidation
            .find_or_create_by!(name: fk_name, table_name: table_name)

          Gitlab::AppLogger.info(
            message: 'Prepared FK for async validation',
            table_name: async_validation.table_name,
            fk_name: async_validation.name)

          async_validation
        end

        def unprepare_async_foreign_key_validation(table_name, column_name = nil, name: nil)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

          return unless async_fk_validation_available?

          fk_name = name || concurrent_foreign_key_name(table_name, column_name)

          PostgresAsyncForeignKeyValidation.find_by(name: fk_name).try(&:destroy)
        end

        def prepare_partitioned_async_foreign_key_validation(table_name, column_name = nil, name: nil)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

          return unless async_fk_validation_available?

          Gitlab::Database::PostgresPartitionedTable.each_partition(table_name) do |partition|
            prepare_async_foreign_key_validation(partition.identifier, column_name, name: name)
          end
        end

        def unprepare_partitioned_async_foreign_key_validation(table_name, column_name = nil, name: nil)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

          return unless async_fk_validation_available?

          Gitlab::Database::PostgresPartitionedTable.each_partition(table_name) do |partition|
            unprepare_async_foreign_key_validation(partition.identifier, column_name, name: name)
          end
        end

        private

        def async_fk_validation_available?
          connection.table_exists?(:postgres_async_foreign_key_validations)
        end
      end
    end
  end
end
