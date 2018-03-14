module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class String < Lexeme::Value
            PATTERN = /("(?<string>.+?)")|('(?<string>.+?)')/.freeze

            def initialize(value)
              @value = value
            end

            def evaluate(variables = {})
              @value.to_s
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
