module Gitlab
  module Ci
    module Pipeline
      module Expression
        class String < Expression::Lexeme
          PATTERN = /"(?<string>.+?)"/.freeze

          def initialize(value)
            @value = value
          end

          def evaluate(**_)
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
