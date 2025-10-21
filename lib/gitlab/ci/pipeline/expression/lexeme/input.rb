# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Input < Lexeme::Value
            PATTERN = /\$\[\[\s*inputs\.(?<name>\w+)\s*\]\]/

            def self.build(string)
              new(string.match(PATTERN)[:name])
            end

            def evaluate(variables = {})
              inputs = variables[:inputs] || {}

              inputs = inputs.with_indifferent_access unless inputs.is_a?(ActiveSupport::HashWithIndifferentAccess)

              inputs.fetch(@value, nil)
            end

            def inspect
              "$[[ inputs.#{@value} ]]"
            end
          end
        end
      end
    end
  end
end
