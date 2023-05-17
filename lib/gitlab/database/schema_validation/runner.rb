# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class Runner
        def initialize(structure_sql, database, validators: Validators::BaseValidator.all_validators)
          @structure_sql = structure_sql
          @database = database
          @validators = validators
        end

        def execute
          validators.flat_map { |c| c.new(structure_sql, database).execute }
        end

        private

        attr_reader :structure_sql, :database, :validators
      end
    end
  end
end
