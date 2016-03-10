module Gitlab
  module Gfm
    module Ast
      module Syntax
        module Markdown
          class CodeBlock < Node
            def allowed
              []
            end

            def to_s
              @text
            end

            def value
              @text
            end

            def lang
              @match[:lang]
            end

            def self.pattern
              /(?<start_token>(```(?<lang>\w+)\n))(?<value>.+?)(?<end_token>\n```)/m
            end
          end
        end
      end
    end
  end
end
