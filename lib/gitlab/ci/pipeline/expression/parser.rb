module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Parser
          def initialize(tokens)
            # raise ArgumentError unless tokens.enumerator?

            @tokens = tokens
            @nodes = []
          end

          def tree
            while token = @tokens.next
              case token.type
              when :operator
                lookbehind = @nodes.last
                lookahead = Parser.new(@tokens).tree

                token.build(lookbehind, lookahead).tap do |node|
                  @nodes.push(node)
                end
              when :value
                token.build.tap do |leaf|
                  @nodes.push(leaf)
                end
              end
            end
          rescue StopIteration
            @nodes.last
          end
        end
      end
    end
  end
end
