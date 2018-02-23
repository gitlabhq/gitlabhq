module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Variable < Lexeme::Base
            PATTERN = /\$(?<name>\w+)/.freeze
            TYPE = :value

            def initialize(name)
              @name = name
            end

            def evaluate(**variables)
            end

            def self.build(string)
              new(string.match(PATTERN)[:name])
            end
          end
        end
      end
    end
  end
end
