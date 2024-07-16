# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class ReplaceTable
        DELIMITER = ";\n\n"

        attr_reader :original_table, :replacement_table, :replaced_table, :primary_key_column,
          :sequence, :original_primary_key, :replacement_primary_key, :replaced_primary_key

        def initialize(connection, original_table, replacement_table, replaced_table, primary_key_column)
          @connection = connection
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

        attr_reader :connection

        delegate :execute, :quote_table_name, :quote_column_name, to: :connection

        def default_sequence(table, column)
          "#{table}_#{column}_seq"
        end

        def default_primary_key(table)
          "#{table}_pkey"
        end

        def sql_to_replace_table
          @sql_to_replace_table ||= combined_sql_statements.map(&:chomp).join(DELIMITER)
        end

        def combined_sql_statements
          statements = []

          statements << alter_column_default(original_table, primary_key_column, expression: nil)
          statements << alter_column_default(replacement_table, primary_key_column,
            expression: "nextval('#{quote_table_name(sequence)}'::regclass)")

          statements << alter_sequence_owned_by(sequence, replacement_table, primary_key_column)

          rename_table_objects(statements, original_table, replaced_table, original_primary_key, replaced_primary_key)
          rename_table_objects(statements, replacement_table, original_table, replacement_primary_key, original_primary_key)

          statements
        end

        def rename_table_objects(statements, old_table, new_table, old_primary_key, new_primary_key)
          statements << rename_table(old_table, new_table)
          statements << rename_constraint(new_table, old_primary_key, new_primary_key)

          rename_partitions(statements, old_table, new_table)
        end

        def rename_partitions(statements, old_table_name, new_table_name)
          Gitlab::Database::PostgresPartition.for_parent_table(old_table_name).each do |partition|
            new_partition_name = partition.name.sub(/#{old_table_name}/, new_table_name.to_s)
            old_primary_key = default_primary_key(partition.name)
            new_primary_key = default_primary_key(new_partition_name)

            statements << rename_constraint(partition.identifier, old_primary_key, new_primary_key)
            statements << rename_table(partition.identifier, new_partition_name)
          end
        end

        def alter_column_default(table_name, column_name, expression:)
          default_clause = expression.nil? ? 'DROP DEFAULT' : "SET DEFAULT #{expression}"

          <<~SQL
            ALTER TABLE #{quote_table_name(table_name)}
            ALTER COLUMN #{quote_column_name(column_name)} #{default_clause}
          SQL
        end

        def alter_sequence_owned_by(sequence_name, table_name, column_name)
          <<~SQL
            ALTER SEQUENCE #{quote_table_name(sequence_name)}
            OWNED BY #{quote_table_name(table_name)}.#{quote_column_name(column_name)}
          SQL
        end

        def rename_table(old_name, new_name)
          <<~SQL
            ALTER TABLE #{quote_table_name(old_name)}
            RENAME TO #{quote_table_name(new_name)}
          SQL
        end

        def rename_constraint(table_name, old_name, new_name)
          <<~SQL
            ALTER TABLE #{quote_table_name(table_name)}
            RENAME CONSTRAINT #{quote_column_name(old_name)} TO #{quote_column_name(new_name)}
          SQL
        end
      end
    end
  end
end
