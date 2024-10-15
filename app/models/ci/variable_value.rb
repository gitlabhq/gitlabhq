# frozen_string_literal: true

# This class provides a hidden variable value computation

module Ci
  class VariableValue
    def initialize(variable)
      @variable = variable
    end

    def evaluate
      variable.hidden? ? nil : variable.value
    end

    private

    attr_reader :variable
  end
end
