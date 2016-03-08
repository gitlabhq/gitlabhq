module Gitlab
  module Gfm
    module Ast
      class Parser
        def initialize(text)
          @text = text
        end

        def tree
          content_nodes.first
        end

        private

        def content_nodes
          Lexer.new(@text, [Syntax::Content]).process!
        end
      end
    end
  end
end
