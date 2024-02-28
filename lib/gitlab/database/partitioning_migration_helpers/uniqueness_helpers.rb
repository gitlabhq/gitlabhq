# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      module UniquenessHelpers
        include Gitlab::Database::MigrationHelpers
        include Gitlab::Database::SchemaHelpers

        COL_NAME = :id
        SequenceError = Class.new(StandardError)

        def ensure_unique_id(table_name)
          function_name = "assign_#{table_name}_id_value"
          trigger_name = "assign_#{table_name}_id_trigger"
          sequences = existing_sequence(table_name, COL_NAME)

          if sequences.many? || sequences.none?
            raise(SequenceError, <<~MESSAGE)
              Expected to find only one sequence for #{table_name}(#{COL_NAME}) but found #{sequences.size}.
              Please ensure that there is only one sequence before proceeding.
              Found sequences: #{sequences.map(&:seq_name)}
            MESSAGE
          end

          return if trigger_exists?(table_name, trigger_name)

          sequence_name = sequences.first.seq_name
          change_column_default(table_name, COL_NAME, nil)

          create_trigger_function(function_name) do
            <<~SQL
              IF NEW."id" IS NOT NULL THEN
                RAISE WARNING 'Manually assigning ids is not allowed, the value will be ignored';
              END IF;
              NEW."id" := nextval(\'#{sequence_name}\'::regclass);
              RETURN NEW;
            SQL
          end

          create_trigger(table_name, trigger_name, function_name, fires: 'BEFORE INSERT')
        end

        private

        def existing_sequence(table_name, col_name)
          Gitlab::Database::PostgresSequence
            .by_table_name(table_name)
            .by_col_name(col_name)
            .to_a
        end
      end
    end
  end
end
