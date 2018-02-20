module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Equality
          PATTERN = /==/.freeze

          def initialize(left, right)
          end

          def evaluate(**variables)
            @left.evaluate(variables) == @right.evaluate(variables)
          end

          def self.build(string)
          end
        end
      end
    end
  end
end
