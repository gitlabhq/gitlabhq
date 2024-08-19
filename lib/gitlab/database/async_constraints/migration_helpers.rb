# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncConstraints
      module MigrationHelpers
        # Prepares a foreign key for asynchronous validation.
        #
        # Stores the FK information in the postgres_async_foreign_key_validations
        # table to be executed later.
        #
        def prepare_async_foreign_key_validation(table_name, column_name = nil, name: nil)
          ensure_async_constraint_validation_is_enabled do
            fk_name = name || concurrent_foreign_key_name(table_name, column_name)

            unless foreign_key_exists?(table_name, name: fk_name)
              raise missing_schema_object_message(table_name, "foreign key", fk_name)
            end

            async_validation = PostgresAsyncConstraintValidation
              .foreign_key_type
              .find_or_create_by!(name: fk_name, table_name: table_name)

            Gitlab::AppLogger.info(
              message: 'Prepared FK for async validation',
              table_name: async_validation.table_name,
              fk_name: async_validation.name)

            async_validation
          end
        end

        def unprepare_async_foreign_key_validation(table_name, column_name = nil, name: nil)
          ensure_async_constraint_validation_is_enabled do
            fk_name = name || concurrent_foreign_key_name(table_name, column_name)

            PostgresAsyncConstraintValidation
              .foreign_key_type
              .find_by(name: fk_name, table_name: table_name)
              .try(&:destroy!)
          end
        end

        def prepare_partitioned_async_foreign_key_validation(table_name, column_name = nil, name: nil)
          ensure_async_constraint_validation_is_enabled do
            Gitlab::Database::PostgresPartitionedTable.each_partition(table_name) do |partition|
              prepare_async_foreign_key_validation(partition.identifier, column_name, name: name)
            end
          end
        end

        def unprepare_partitioned_async_foreign_key_validation(table_name, column_name = nil, name: nil)
          ensure_async_constraint_validation_is_enabled do
            Gitlab::Database::PostgresPartitionedTable.each_partition(table_name) do |partition|
              unprepare_async_foreign_key_validation(partition.identifier, column_name, name: name)
            end
          end
        end

        # Prepares a check constraint for asynchronous validation.
        #
        # Stores the constraint information in the postgres_async_foreign_key_validations
        # table to be executed later.
        #
        def prepare_async_check_constraint_validation(table_name, name:)
          ensure_async_constraint_validation_is_enabled do
            unless check_constraint_exists?(table_name, name)
              raise missing_schema_object_message(table_name, "check constraint", name)
            end

            async_validation = PostgresAsyncConstraintValidation
              .check_constraint_type
              .find_or_create_by!(name: name, table_name: table_name)

            Gitlab::AppLogger.info(
              message: 'Prepared check constraint for async validation',
              table_name: async_validation.table_name,
              constraint_name: async_validation.name)

            async_validation
          end
        end

        def unprepare_async_check_constraint_validation(table_name, name:)
          ensure_async_constraint_validation_is_enabled do
            PostgresAsyncConstraintValidation
              .check_constraint_type
              .find_by(name: name, table_name: table_name)
              .try(&:destroy!)
          end
        end

        def prepare_partitioned_async_check_constraint_validation(table_name, name: nil)
          ensure_async_constraint_validation_is_enabled do
            Gitlab::Database::PostgresPartitionedTable.each_partition(table_name) do |partition|
              prepare_async_check_constraint_validation(partition.identifier, name: name)
            end
          end
        end

        def unprepare_partitioned_async_check_constraint_validation(table_name, name: nil)
          ensure_async_constraint_validation_is_enabled do
            Gitlab::Database::PostgresPartitionedTable.each_partition(table_name) do |partition|
              unprepare_async_check_constraint_validation(partition.identifier, name: name)
            end
          end
        end

        private

        def ensure_async_constraint_validation_is_enabled
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!
          return unless PostgresAsyncConstraintValidation.table_available?

          yield
        end
      end
    end
  end
end
