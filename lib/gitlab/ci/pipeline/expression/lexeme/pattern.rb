module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          require_dependency 're2'

          class Pattern < Lexeme::Value
            PATTERN = %r{/(?<regexp>.+)/}.freeze

            def initialize(regexp)
              @value = regexp
            end

            def evaluate(variables = {})
              @regexp = Gitlab::UntrustedRegexp.new(@value)
            rescue RegexpError
              raise Expression::RuntimeError, 'Invalid regular expression!'
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
