# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class MissingIndexes < BaseValidator
          ERROR_MESSAGE = "The index %s is missing from the database"

          def execute
            structure_sql.indexes.filter_map do |structure_sql_index|
              next if database.index_exists?(structure_sql_index.name)

              build_inconsistency(self.class, structure_sql_index, nil)
            end
          end
        end
      end
    end
  end
end
