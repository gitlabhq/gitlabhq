# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class DifferentDefinitionIndexes < Base
          ERROR_MESSAGE = 'The %s index has a different statement between structure.sql and database'

          def execute
            structure_sql.indexes.filter_map do |structure_sql_index|
              database_index = database.fetch_index_by_name(structure_sql_index.name)

              next if database_index.nil?
              next if database_index.statement == structure_sql_index.statement

              build_inconsistency(self.class, structure_sql_index, database_index)
            end
          end
        end
      end
    end
  end
end
