# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Variable < Lexeme::Value
            PATTERN = /\$(?<name>\w+)/.freeze

            def evaluate(variables = {})
              variables.with_indifferent_access.fetch(@value, nil)
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
