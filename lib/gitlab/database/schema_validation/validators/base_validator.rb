# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class BaseValidator
          ERROR_MESSAGE = 'A schema inconsistency has been found'

          def initialize(structure_sql, database)
            @structure_sql = structure_sql
            @database = database
          end

          def self.all_validators
            [
              ExtraTables,
              ExtraTableColumns,
              ExtraIndexes,
              ExtraTriggers,
              MissingTables,
              MissingTableColumns,
              MissingIndexes,
              MissingTriggers,
              DifferentDefinitionTables,
              DifferentDefinitionIndexes,
              DifferentDefinitionTriggers
            ]
          end

          def execute
            raise NoMethodError, "subclasses of #{self.class.name} must implement #{__method__}"
          end

          private

          attr_reader :structure_sql, :database

          def build_inconsistency(validator_class, structure_sql_object, database_object)
            Inconsistency.new(validator_class, structure_sql_object, database_object)
          end
        end
      end
    end
  end
end
