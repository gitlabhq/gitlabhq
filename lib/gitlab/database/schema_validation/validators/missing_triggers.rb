# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module Validators
        class MissingTriggers < BaseValidator
          def execute
            structure_sql.triggers.filter_map do |index|
              next if database.trigger_exists?(index.name)

              build_inconsistency(self.class, index)
            end
          end
        end
      end
    end
  end
end
