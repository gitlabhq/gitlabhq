module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Variable < Lexeme::Value
            PATTERN = /\$(?<name>\w+)/.freeze

            def initialize(name)
              @name = name
            end

            def evaluate(variables = {})
              HashWithIndifferentAccess.new(variables).fetch(@name, nil)
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
