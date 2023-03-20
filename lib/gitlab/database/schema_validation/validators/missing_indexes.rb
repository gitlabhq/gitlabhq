# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class MissingIndexes < BaseValidator
          def execute
            structure_sql.indexes.filter_map do |index|
              next if database.index_exists?(index.name)

              build_inconsistency(self.class, index)
            end
          end
        end
      end
    end
  end
end
