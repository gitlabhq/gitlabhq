# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class ExtraIndexes < BaseValidator
          def execute
            database.indexes.filter_map do |index|
              next if structure_sql.index_exists?(index.name)

              build_inconsistency(self.class, index)
            end
          end
        end
      end
    end
  end
end
