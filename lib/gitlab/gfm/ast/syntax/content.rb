module Gitlab
  module Gfm
    module Ast
      module Syntax
        ##
        # Main GFM content
        #
        class Content < Node
          def self.allowed
            [Syntax::Markdown::CodeBlock, Syntax::Text]
          end

          def self.pattern
            /(?<value>.+)/m
          end

          def to_s
            nodes.map(&:to_s).join
          end
        end
      end
    end
  end
end
