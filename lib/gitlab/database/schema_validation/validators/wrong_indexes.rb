# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class WrongIndexes < BaseValidator
          def execute
            structure_sql.indexes.filter_map do |structure_sql_index|
              database_index = database.fetch_index_by_name(structure_sql_index.name)

              next if database_index.nil?
              next if database_index.statement == structure_sql_index.statement

              build_inconsistency(structure_sql_index)
            end
          end
        end
      end
    end
  end
end
