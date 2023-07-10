# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class MissingIndexes < Base
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
