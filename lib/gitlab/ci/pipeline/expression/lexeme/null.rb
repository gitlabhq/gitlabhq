module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Null < Lexeme::Base
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
end
