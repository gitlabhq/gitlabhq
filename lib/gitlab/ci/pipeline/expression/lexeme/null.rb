module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Null < Lexeme::Value
            PATTERN = /null/.freeze

            def initialize(value = nil)
              @value = nil
            end

            def evaluate(variables = {})
              nil
            end

            def self.build(_value)
              self.new
            end
          end
        end
      end
    end
  end
end
