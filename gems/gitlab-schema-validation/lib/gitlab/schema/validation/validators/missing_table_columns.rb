# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class MissingTableColumns < Base
          ERROR_MESSAGE = "The table %s has columns missing from the database"

          def execute
            structure_sql.tables.filter_map do |structure_sql_table|
              table_name = structure_sql_table.name
              database_table = database.fetch_table_by_name(table_name)

              next unless database_table

              inconsistencies = structure_sql_table.columns.reject do |structure_table_column|
                database_table.column_exists?(structure_table_column.name)
              end

              if inconsistencies.any?
                build_inconsistency(self.class, nil, SchemaObjects::Table.new(table_name, inconsistencies))
              end
            end
          end
        end
      end
    end
  end
end
