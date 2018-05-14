module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Pattern < Lexeme::Value
            PATTERN = %r{/(?<regexp>.+)/}.freeze

            def initialize(regexp)
              @value = regexp
            end

            def evaluate(variables = {})
              # TODO multiline support
              @regexp = Gitlab::UntrustedRegexp.new(@value)
            rescue RegexpError
              raise Parser::ParserError, 'Invalid regular expression!'
            end

            def self.build(string)
              new(string.match(PATTERN)[:regexp])
            end
          end
        end
      end
    end
  end
end
