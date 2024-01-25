# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      module UniquenessHelpers
        include Gitlab::Database::MigrationHelpers
        include Gitlab::Database::SchemaHelpers

        def ensure_unique_id(table_name)
          function_name = "assign_#{table_name}_id_value"
          trigger_name = "assign_#{table_name}_id_trigger"

          return if trigger_exists?(table_name, trigger_name)

          change_column_default(table_name, :id, nil)

          create_trigger_function(function_name) do
            <<~SQL
              IF NEW."id" IS NOT NULL THEN
                RAISE WARNING 'Manually assigning ids is not allowed, the value will be ignored';
              END IF;
              NEW."id" := nextval(\'#{existing_sequence(table_name)}\'::regclass);
              RETURN NEW;
            SQL
          end

          create_trigger(table_name, trigger_name, function_name, fires: 'BEFORE INSERT')
        end

        private

        def existing_sequence(table_name)
          Gitlab::Database::PostgresSequence.by_table_name(table_name).first.seq_name
        end
      end
    end
  end
end
