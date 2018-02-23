module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Parser
          def initialize(tokens)
            @tokens = tokens.to_enum
            @nodes = []
          end

          def tree
            while token = @tokens.next
              case token.type
              when :operator
                token.build(@nodes.last, tree).tap do |node|
                  @nodes.push(node)
                end
              when :value
                token.build.tap do |leaf|
                  @nodes.push(leaf)
                end
              end
            end
          rescue StopIteration
            @nodes.last || Expression::Null.new
          end

          def self.seed(statement)
            new(Expression::Lexer.new(statement).tokens)
          end
        end
      end
    end
  end
end
