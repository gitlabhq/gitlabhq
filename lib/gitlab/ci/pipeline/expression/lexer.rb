module Gitlab
  module Ci
    module Pipeline
      module Expression
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
