# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class ExtraIndexes < BaseValidator
          ERROR_MESSAGE = "The index %s is present in the database, but not in the structure.sql file"

          def execute
            database.indexes.filter_map do |database_index|
              next if structure_sql.index_exists?(database_index.name)

              build_inconsistency(self.class, nil, database_index)
            end
          end
        end
      end
    end
  end
end
