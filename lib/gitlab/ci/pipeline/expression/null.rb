module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Null < Expression::Lexeme
          PATTERN = /null/.freeze
          TYPE = :value

          def initialize(value = nil)
            @value = value
          end

          def evaluate(**_)
            nil
          end
        end
      end
    end
  end
end
