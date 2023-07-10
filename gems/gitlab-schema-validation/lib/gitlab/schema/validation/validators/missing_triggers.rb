# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class MissingTriggers < Base
          ERROR_MESSAGE = "The trigger %s is missing from the database"

          def execute
            structure_sql.triggers.filter_map do |structure_sql_trigger|
              next if database.trigger_exists?(structure_sql_trigger.name)

              build_inconsistency(self.class, structure_sql_trigger, nil)
            end
          end
        end
      end
    end
  end
end
