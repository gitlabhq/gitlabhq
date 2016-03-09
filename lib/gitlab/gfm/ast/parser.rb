module Gitlab
  module Gfm
    module Ast
      class Parser
        attr_reader :tree

        def initialize(text)
          @text = text
          @lexer = Lexer.new(@text, [Syntax::Content])
          @nodes = @lexer.process!
        end

        def tree
          @nodes.first
        end

        def recreate
          tree.to_s
        end
      end
    end
  end
end
