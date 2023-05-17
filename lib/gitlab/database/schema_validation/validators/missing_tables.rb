# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class MissingTables < BaseValidator
          ERROR_MESSAGE = "The table %s is missing from the database"

          def execute
            structure_sql.tables.filter_map do |structure_sql_table|
              next if database.table_exists?(structure_sql_table.name)

              build_inconsistency(self.class, structure_sql_table, nil)
            end
          end
        end
      end
    end
  end
end
