# frozen_string_literal: true

module ExpandVariables
  class << self
    def expand(value, variables)
      variables_hash = nil

      value.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) do
        variables_hash ||= transform_variables(variables)
        variables_hash[$1 || $2]
      end
    end

    private

    def transform_variables(variables)
      # Lazily initialise variables
      variables = variables.call if variables.is_a?(Proc)

      # Convert hash array to variables
      if variables.is_a?(Array)
        variables = variables.reduce({}) do |hash, variable|
          hash[variable[:key]] = variable[:value]
          hash
        end
      end

      variables
    end
  end
end
