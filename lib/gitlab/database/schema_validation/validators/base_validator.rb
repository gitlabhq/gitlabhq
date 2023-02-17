# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class BaseValidator
          Inconsistency = Struct.new(:name, :statement)

          def initialize(structure_sql, database)
            @structure_sql = structure_sql
            @database = database
          end

          def self.all_validators
            [
              ExtraIndexes,
              MissingIndexes,
              WrongIndexes
            ]
          end

          def execute
            raise NoMethodError, "subclasses of #{self.class.name} must implement #{__method__}"
          end

          private

          attr_reader :structure_sql, :database

          def build_inconsistency(schema_object)
            Inconsistency.new(schema_object.name, schema_object.statement)
          end
        end
      end
    end
  end
end
