# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        module Functions
          class ExpandVars < Base
            def self.function_expression_pattern
              /^#{name}$/
            end

            def self.name
              'expand_vars'
            end

            def execute(input_value)
              unless input_value.is_a?(String)
                error("invalid input type: #{self.class.name} can only be used with string inputs")
                return
              end

              ExpandVariables.expand_existing(input_value, ctx.variables, fail_on_masked: true)
            rescue ExpandVariables::VariableExpansionError => e
              error("variable expansion error: #{e.message}")
              nil
            end
          end
        end
      end
    end
  end
end
