module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Equals < Lexeme::Operator
            PATTERN = /==/.freeze

            def initialize(left, right)
              @left = left
              @right = right
            end

            def evaluate(variables = {})
              @left.evaluate(variables) == @right.evaluate(variables)
            end

            def self.build(_value, behind, ahead)
              new(behind, ahead)
            end
          end
        end
      end
    end
  end
end
