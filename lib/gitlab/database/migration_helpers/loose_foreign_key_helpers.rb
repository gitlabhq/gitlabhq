# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module LooseForeignKeyHelpers
        include Gitlab::Database::SchemaHelpers

        POSTGRES_IDENTIFIER_LIMIT = 63

        INSERT_FUNCTION_NAME = 'insert_into_loose_foreign_keys_deleted_records'
        INSERT_FUNCTION_NAME_OVERRIDE_TABLE = 'insert_into_loose_foreign_keys_deleted_records_override_table'

        # This adds a LFK standard trigger to tables, where the loose_foreign_keys_deleted_records
        # record is referencing the table. This should be used for non-partitioned tables.
        def track_record_deletions(table_name)
          trigger_name = record_deletion_trigger_name(table_name)

          execute(<<~SQL.squish)
            CREATE TRIGGER #{trigger_name}
            AFTER DELETE ON #{table_name} REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT
            EXECUTE FUNCTION #{INSERT_FUNCTION_NAME}();
          SQL
        end

        # This is used to track deletions on partitioned tables and their partitions.
        # parent_table is the table name that is insert into loose_foreign_keys_deleted_records table
        # it defaults to the table_name, and that's for when we track deletions on partitioned (parent) tables.
        def track_record_deletions_override_table_name(table_identifier, parent_table = nil)
          table_name = table_identifier.to_s.split('.').last
          parent_table ||= table_name

          execute(<<~SQL.squish)
            CREATE TRIGGER #{record_deletion_trigger_name(table_name)}
            AFTER DELETE ON #{table_identifier} REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT
            EXECUTE FUNCTION
            #{INSERT_FUNCTION_NAME_OVERRIDE_TABLE}(#{connection.quote(parent_table)});
          SQL
        end

        # This method also works on tables that are not in the default schema, but
        # the full table identifier has to be passed in this case.
        def untrack_record_deletions(table, trigger_name: nil)
          trigger_name ||= record_deletion_trigger_name(table)
          drop_trigger(table, trigger_name)
        end

        def has_loose_foreign_key?(table)
          trigger_exists?(table, record_deletion_trigger_name(table))
        end

        def track_record_deletions_with_custom_column(
          table, column:, parent_table: nil,
          function_name: nil, trigger_name: nil)
          table_name = table.to_s.split('.').last
          parent_table ||= table_name

          function_name ||= "lfk_deleted_records_for_#{column}"
          trigger_name ||= "#{table_name}_loose_fk"

          validate_identifier_length!(function_name)
          validate_identifier_length!(trigger_name)
          validate_column_uniqueness!(table, column)

          create_trigger_function(function_name, replace: true) do
            <<~SQL
              INSERT INTO loose_foreign_keys_deleted_records
              (fully_qualified_table_name, primary_key_value)
              SELECT current_schema() || '.' || TG_ARGV[0], old_table.#{connection.quote_column_name(column)}
              FROM old_table;

              RETURN NULL;
            SQL
          end

          execute(<<~SQL)
            CREATE TRIGGER #{trigger_name}
            AFTER DELETE ON #{table}
            REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT
            EXECUTE FUNCTION #{function_name}(#{connection.quote(parent_table)});
          SQL
        end

        private

        def record_deletion_trigger_name(table)
          table_name = table.to_s.split('.').last
          "#{table_name}_loose_fk_trigger"
        end

        def validate_column_uniqueness!(table, column)
          column_name = column.to_s

          return if connection.primary_keys(table) == [column_name]
          return if connection.index_exists?(table, column_name, unique: true)

          raise ArgumentError, "Column '#{column_name}' on table '#{table}' must have a unique index " \
            "or be the sole primary key. Tracking deletions with a non-unique column can cause accidental data loss."
        end

        def validate_identifier_length!(name)
          return if name.to_s.length <= POSTGRES_IDENTIFIER_LIMIT

          raise ArgumentError, "Identifier '#{name}' is too long " \
            "(#{name.length}/#{POSTGRES_IDENTIFIER_LIMIT} characters)."
        end
      end
    end
  end
end
