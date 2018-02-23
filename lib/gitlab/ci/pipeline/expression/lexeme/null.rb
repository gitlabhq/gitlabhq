module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Null < Lexeme::Value
            PATTERN = /null/.freeze

            def initialize(value = nil)
              @value = value
            end

            def evaluate(**_)
              nil
            end

            def self.build(value)
              new(value)
            end
          end
        end
      end
    end
  end
end
