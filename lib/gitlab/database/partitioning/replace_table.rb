# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class ReplaceTable
        DELIMITER = ";\n\n"

        attr_reader :original_table, :replacement_table, :replaced_table, :primary_key_column,
          :sequence, :original_primary_key, :replacement_primary_key, :replaced_primary_key

        def initialize(original_table, replacement_table, replaced_table, primary_key_column)
          @original_table = original_table
          @replacement_table = replacement_table
          @replaced_table = replaced_table
          @primary_key_column = primary_key_column

          @sequence = default_sequence(original_table, primary_key_column)
          @original_primary_key = default_primary_key(original_table)
          @replacement_primary_key = default_primary_key(replacement_table)
          @replaced_primary_key = default_primary_key(replaced_table)
        end

        def perform
          yield sql_to_replace_table if block_given?

          execute(sql_to_replace_table)
        end

        private

        delegate :execute, :quote_table_name, :quote_column_name, to: :connection
        def connection
          @connection ||= ActiveRecord::Base.connection
        end

        def default_sequence(table, column)
          "#{table}_#{column}_seq"
        end

        def default_primary_key(table)
          "#{table}_pkey"
        end

        def sql_to_replace_table
          @sql_to_replace_table ||= [
            drop_default_sql(original_table, primary_key_column),
            set_default_sql(replacement_table, primary_key_column, "nextval('#{quote_table_name(sequence)}'::regclass)"),

            change_sequence_owner_sql(sequence, replacement_table, primary_key_column),

            rename_table_sql(original_table, replaced_table),
            rename_constraint_sql(replaced_table, original_primary_key, replaced_primary_key),

            rename_table_sql(replacement_table, original_table),
            rename_constraint_sql(original_table, replacement_primary_key, original_primary_key)
          ].join(DELIMITER)
        end

        def drop_default_sql(table, column)
          "ALTER TABLE #{quote_table_name(table)} ALTER COLUMN #{quote_column_name(column)} DROP DEFAULT"
        end

        def set_default_sql(table, column, expression)
          "ALTER TABLE #{quote_table_name(table)} ALTER COLUMN #{quote_column_name(column)} SET DEFAULT #{expression}"
        end

        def change_sequence_owner_sql(sequence, table, column)
          "ALTER SEQUENCE #{quote_table_name(sequence)} OWNED BY #{quote_table_name(table)}.#{quote_column_name(column)}"
        end

        def rename_table_sql(old_name, new_name)
          "ALTER TABLE #{quote_table_name(old_name)} RENAME TO #{quote_table_name(new_name)}"
        end

        def rename_constraint_sql(table, old_name, new_name)
          "ALTER TABLE #{quote_table_name(table)} RENAME CONSTRAINT #{quote_column_name(old_name)} TO #{quote_column_name(new_name)}"
        end
      end
    end
  end
end
