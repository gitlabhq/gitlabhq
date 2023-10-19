# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Variable < Lexeme::Value
            PATTERN = /\$(?<name>\w+)/

            def evaluate(variables = {})
              unless variables.is_a?(ActiveSupport::HashWithIndifferentAccess)
                variables = variables.with_indifferent_access
              end

              variables.fetch(@value, nil)
            end

            def inspect
              "$#{@value}"
            end

            def self.build(string)
              new(string.match(PATTERN)[:name])
            end
          end
        end
      end
    end
  end
end
