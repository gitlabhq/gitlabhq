# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class DifferentDefinitionTables < Base
          ERROR_MESSAGE = "The table %s has a different column statement between structure.sql and database"

          def execute
            structure_sql.tables.filter_map do |structure_sql_table|
              table_name = structure_sql_table.name
              database_table = database.fetch_table_by_name(table_name)

              next unless database_table

              db_diffs, structure_diffs = column_diffs(database_table, structure_sql_table.columns)

              if db_diffs.any?
                build_inconsistency(self.class,
                  SchemaObjects::Table.new(table_name, db_diffs),
                  SchemaObjects::Table.new(table_name, structure_diffs))
              end
            end
          end

          private

          def column_diffs(db_table, columns)
            db_diffs = []
            structure_diffs = []

            columns.each do |column|
              # Sliding-list partitioning moves the partition key default at run time, so it differs per instance
              next if column.partition_key?

              db_column = db_table.fetch_column_by_name(column.name)

              next unless db_column

              next if db_column.statement == column.statement

              db_diffs << db_column
              structure_diffs << column
            end

            [db_diffs, structure_diffs]
          end
        end
      end
    end
  end
end
