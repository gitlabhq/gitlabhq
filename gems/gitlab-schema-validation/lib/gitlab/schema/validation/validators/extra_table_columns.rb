# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class ExtraTableColumns < Base
          ERROR_MESSAGE = "The table %s has columns present in the database, but not in the structure.sql file"

          def execute
            database.tables.filter_map do |database_table|
              table_name = database_table.name
              structure_sql_table = structure_sql.fetch_table_by_name(table_name)

              next unless structure_sql_table

              inconsistencies = database_table.columns.reject do |database_table_column|
                structure_sql_table.column_exists?(database_table_column.name)
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
