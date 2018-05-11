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
              Gitlab::UntrustedRegexp.new(@value.to_s)
              # TODO raise LexerError / ParserError in case of RegexpError
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
