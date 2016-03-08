module Gitlab
  module Gfm
    module Ast
      module Syntax
        module Markdown
          class CodeBlock < Node
            def to_s
              @match[:start_token] + @value + @match[:end_token]
            end

            def lang
              @match[:lang]
            end

            def self.allowed
              []
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
