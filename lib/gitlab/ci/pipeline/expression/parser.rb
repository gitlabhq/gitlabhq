module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Parser
          def initialize(syntax)
            if syntax.is_a?(Expression::Lexer)
              @tokens = syntax.tokens
            else
              @tokens = syntax.to_a
            end
          end

          def tree
            if @tokens.many?
              Expression::Equals.new(@tokens.first.build, @tokens.last.build)
            else
              @tokens.first.build
            end
          end
        end
      end
    end
  end
end
