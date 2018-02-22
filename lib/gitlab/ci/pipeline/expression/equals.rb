module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Equals < Expression::Lexeme
          PATTERN = /==/.freeze
          TYPE = :operator

          def initialize(left, right)
            @left = left
            @right = right
          end

          def evaluate(**variables)
            @left.evaluate(variables) == @right.evaluate(variables)
          end

          def self.build(value, behind, ahead)
            new(behind, ahead)
          end
        end
      end
    end
  end
end
