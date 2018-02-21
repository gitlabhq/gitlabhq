module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Equals < Expression::Lexeme
          PATTERN = /==/.freeze

          def initialize(left, right)
            @left = left
            @right = right
          end

          def evaluate(**variables)
            @left.evaluate(variables) == @right.evaluate(variables)
          end
        end
      end
    end
  end
end
