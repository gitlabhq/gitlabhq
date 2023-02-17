# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class Runner
        def initialize(structure_sql, database)
          @structure_sql = structure_sql
          @database = database
        end

        def execute
          validator_classes = Validators::BaseValidator.all_validators

          validator_classes.flat_map { |c| c.new(structure_sql, database).execute }
        end

        private

        attr_reader :structure_sql, :database
      end
    end
  end
end
