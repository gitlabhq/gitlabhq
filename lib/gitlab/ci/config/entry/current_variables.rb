# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents CI/CD variables.
        # The class will be renamed to `Variables` when removing the FF `ci_variables_refactoring_to_variable`.
        #
        class CurrentVariables < ::Gitlab::Config::Entry::ComposableHash
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, type: Hash
          end

          # Enable these lines when removing the FF `ci_variables_refactoring_to_variable`
          # and renaming this class to `Variables`.
          # def self.default(**)
          #   {}
          # end

          def value
            @entries.to_h do |key, entry|
              [key.to_s, entry.value]
            end
          end

          def value_with_data
            @entries.to_h do |key, entry|
              [key.to_s, entry.value_with_data]
            end
          end

          private

          def composable_class(_name, _config)
            Entry::Variable
          end

          def composable_metadata
            { allowed_value_data: opt(:allowed_value_data) }
          end
        end
      end
    end
  end
end
