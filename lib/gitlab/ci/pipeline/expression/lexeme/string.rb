# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class String < Lexeme::Value
            PATTERN = /("(?<string>.*?)")|('(?<string>.*?)')/

            def evaluate(variables = {})
              @value.to_s
            end

            def inspect
              @value.inspect
            end

            def self.build(string)
              new(string.match(PATTERN)[:string])
            end
          end
        end
      end
    end
  end
end
