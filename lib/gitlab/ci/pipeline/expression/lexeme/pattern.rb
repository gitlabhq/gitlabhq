module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          require_dependency 're2'

          class Pattern < Lexeme::Value
            PATTERN = %r{^/.+/[ismU]*$}.freeze

            def initialize(regexp)
              @value = regexp

              unless Gitlab::UntrustedRegexp.valid?(@value)
                raise Lexer::SyntaxError, 'Invalid regular expression!'
              end
            end

            def evaluate(variables = {})
              Gitlab::UntrustedRegexp.fabricate(@value)
            rescue RegexpError
              raise Expression::RuntimeError, 'Invalid regular expression!'
            end

            def self.build(string)
              new(string)
            end
          end
        end
      end
    end
  end
end
