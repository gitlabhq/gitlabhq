# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents CI/CD variables.
        # CurrentVariables will be renamed to this class when removing the FF `ci_variables_refactoring_to_variable`.
        #
        class Variables
          def self.new(...)
            if YamlProcessor::FeatureFlags.enabled?(:ci_variables_refactoring_to_variable)
              CurrentVariables.new(...)
            else
              LegacyVariables.new(...)
            end
          end

          def self.default(**)
            {}
          end
        end
      end
    end
  end
end
