module Gitlab
  module Ci
    module Pipeline
      module Expression
        GRAMMAR = [
          %w[variable equals string],
          %w[variable equals variable],
          %w[variable equals null],
          %w[string equals variable],
          %w[null equals variable],
        ]

        class Lexer
          def initialize(statement)
            @statement = statement
          end

          def tokenize
          end
        end
      end
    end
  end
end
