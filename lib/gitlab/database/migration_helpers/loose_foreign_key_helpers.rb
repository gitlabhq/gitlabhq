# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module LooseForeignKeyHelpers
        include Gitlab::Database::SchemaHelpers

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
        def untrack_record_deletions(table)
          trigger_name = record_deletion_trigger_name(table)
          drop_trigger(table, trigger_name)
        end

        def has_loose_foreign_key?(table)
          trigger_exists?(table, record_deletion_trigger_name(table))
        end

        private

        def record_deletion_trigger_name(table)
          table_name = table.to_s.split('.').last
          "#{table_name}_loose_fk_trigger"
        end
      end
    end
  end
end
