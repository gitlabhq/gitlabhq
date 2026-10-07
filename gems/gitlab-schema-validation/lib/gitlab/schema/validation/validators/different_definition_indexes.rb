# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class DifferentDefinitionIndexes < Base
          ERROR_MESSAGE = 'The %s index has a different statement between structure.sql and database'

          def execute
            structure_sql.indexes.filter_map do |structure_sql_index|
              database_index = counterpart(structure_sql_index)

              next if database_index.nil?
              next unless index_different?(structure_sql_index, database_index)

              build_inconsistency(self.class, structure_sql_index, database_index)
            end
          end

          private

          def counterpart(index)
            partition_index_matcher.counterpart(index)
          end

          def index_different?(structure_sql_index, database_index)
            return database_index.definition != structure_sql_index.definition if structure_sql_index.attachment

            database_index.statement != structure_sql_index.statement
          end
        end
      end
    end
  end
end
