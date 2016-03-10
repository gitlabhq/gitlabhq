module Gitlab
  module Gfm
    module Ast
      class Parser
        attr_reader :tree, :text

        def initialize(text)
          @text = text
          @tree = Lexer.single(text, Syntax::Content)
        end

        def recreate
          tree.to_s
        end
      end
    end
  end
end
