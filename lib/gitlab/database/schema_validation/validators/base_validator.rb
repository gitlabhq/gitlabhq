# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class BaseValidator
          Inconsistency = Struct.new(:type, :object_name, :statement)

          def initialize(structure_sql, database)
            @structure_sql = structure_sql
            @database = database
          end

          def self.all_validators
            [
              ExtraIndexes,
              ExtraTriggers,
              MissingIndexes,
              MissingTriggers,
              DifferentDefinitionIndexes,
              DifferentDefinitionTriggers
            ]
          end

          def execute
            raise NoMethodError, "subclasses of #{self.class.name} must implement #{__method__}"
          end

          private

          attr_reader :structure_sql, :database

          def build_inconsistency(validator_class, schema_object)
            inconsistency_type = validator_class.name.demodulize.underscore

            Inconsistency.new(inconsistency_type, schema_object.name, schema_object.statement)
          end
        end
      end
    end
  end
end
