module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Parser
          def initialize(tokens)
            @tokens = tokens.to_enum
            @nodes = []
          end

          ##
          # This produces a reverse descent parse tree.
          #
          # It currently does not support precedence of operators.
          #
          def tree
            while token = @tokens.next
              case token.type
              when :operator
                token.build(@nodes.pop, tree).tap do |node|
                  @nodes.push(node)
                end
              when :value
                token.build.tap do |leaf|
                  @nodes.push(leaf)
                end
              end
            end
          rescue StopIteration
            @nodes.last || Lexeme::Null.new
          end

          def self.seed(statement)
            new(Expression::Lexer.new(statement).tokens)
          end
        end
      end
    end
  end
end
