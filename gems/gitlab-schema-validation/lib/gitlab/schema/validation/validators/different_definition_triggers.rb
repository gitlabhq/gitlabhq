# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class DifferentDefinitionTriggers < Base
          ERROR_MESSAGE = "The %s trigger has a different statement between structure.sql and database"

          def execute
            structure_sql.triggers.filter_map do |structure_sql_trigger|
              database_trigger = database.fetch_trigger_by_name(structure_sql_trigger.name)

              next if database_trigger.nil?
              next if database_trigger.statement == structure_sql_trigger.statement

              build_inconsistency(self.class, structure_sql_trigger, nil)
            end
          end
        end
      end
    end
  end
end
