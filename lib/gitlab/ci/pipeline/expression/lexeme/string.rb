module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class String < Lexeme::Base
            PATTERN = /"(?<string>.+?)"/.freeze
            TYPE = :value

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
end
