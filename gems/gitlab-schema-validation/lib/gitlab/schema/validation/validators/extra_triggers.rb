# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class ExtraTriggers < Base
          ERROR_MESSAGE = "The trigger %s is present in the database, but not in the structure.sql file"

          # Copy function of an integer-to-bigint conversion. Its trigger name is a hash shared with other
          # trigger kinds, so only the function body identifies it.
          BIGINT_CONVERSION_FUNCTION = /NEW\."\w+_convert_to_bigint" := NEW\./

          def execute
            database.triggers.filter_map do |database_trigger|
              next if structure_sql.trigger_exists?(database_trigger.name)
              next if database_trigger.function_body.to_s.match?(BIGINT_CONVERSION_FUNCTION)

              build_inconsistency(self.class, nil, database_trigger)
            end
          end
        end
      end
    end
  end
end
