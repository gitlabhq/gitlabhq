# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class ExtraTriggers < BaseValidator
          def execute
            database.triggers.filter_map do |trigger|
              next if structure_sql.trigger_exists?(trigger.name)

              build_inconsistency(self.class, trigger)
            end
          end
        end
      end
    end
  end
end
