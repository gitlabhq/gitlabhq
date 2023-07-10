# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class ExtraTriggers < Base
          ERROR_MESSAGE = "The trigger %s is present in the database, but not in the structure.sql file"

          def execute
            database.triggers.filter_map do |database_trigger|
              next if structure_sql.trigger_exists?(database_trigger.name)

              build_inconsistency(self.class, nil, database_trigger)
            end
          end
        end
      end
    end
  end
end
