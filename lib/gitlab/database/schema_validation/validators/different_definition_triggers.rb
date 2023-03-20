# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class DifferentDefinitionTriggers < BaseValidator
          def execute
            structure_sql.triggers.filter_map do |structure_sql_trigger|
              database_trigger = database.fetch_trigger_by_name(structure_sql_trigger.name)

              next if database_trigger.nil?
              next if database_trigger.statement == structure_sql_trigger.statement

              build_inconsistency(self.class, structure_sql_trigger)
            end
          end
        end
      end
    end
  end
end
