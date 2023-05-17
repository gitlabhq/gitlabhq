# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module LooseForeignKeyHelpers
        include Gitlab::Database::SchemaHelpers

        DELETED_RECORDS_INSERT_FUNCTION_NAME = 'insert_into_loose_foreign_keys_deleted_records'

        def track_record_deletions(table)
          execute(<<~SQL.squish)
            CREATE TRIGGER #{record_deletion_trigger_name(table)}
            AFTER DELETE ON #{table} REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT
            EXECUTE FUNCTION #{DELETED_RECORDS_INSERT_FUNCTION_NAME}();
          SQL
        end

        def untrack_record_deletions(table)
          drop_trigger(table, record_deletion_trigger_name(table))
        end

        def has_loose_foreign_key?(table)
          trigger_exists?(table, record_deletion_trigger_name(table))
        end

        private

        def record_deletion_trigger_name(table)
          "#{table}_loose_fk_trigger"
        end
      end
    end
  end
end
