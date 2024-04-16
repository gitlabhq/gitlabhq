# frozen_string_literal: true

# This class provides a hidden variable value computation

module Ci
  class VariableValue
    def initialize(variable)
      @variable = variable
    end

    def evaluate
      return variable.value if feature_flag_is_disabled?

      variable.hidden? ? nil : variable.value
    end

    private

    # This logic will go away on the ff `ci_hidden_variables` deprecation
    def feature_flag_is_disabled?
      parent = if variable.is_a?(Ci::Variable)
                 variable.project
               elsif variable.is_a?(Ci::GroupVariable)
                 variable.group
               end

      ::Feature.disabled?(:ci_hidden_variables, parent)
    end

    attr_reader :variable
  end
end
