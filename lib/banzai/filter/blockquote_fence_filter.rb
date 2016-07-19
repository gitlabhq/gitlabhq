module Banzai
  module Filter
    class BlockquoteFenceFilter < HTML::Pipeline::TextFilter
      REGEX = %r{
          (?<code>
            # Code blocks:
            # ```
            # Anything, including `>>>` blocks which are ignored by this filter
            # ```

            ^```
            .+?
            \n```$
          )
        |
          (?<html>
            # HTML block:
            # <tag>
            # Anything, including `>>>` blocks which are ignored by this filter
            # </tag>

            ^<[^>]+?>\n
            .+?
            \n<\/[^>]+?>$
          )
        |
          (?:
            # Blockquote:
            # >>>
            # Anything, including code and HTML blocks
            # >>>

            ^>>>\n
            (?<quote>
              (?:
                  # Any character that doesn't introduce a code or HTML block
                  (?!
                      ^```
                    |
                      ^<[^>]+?>\n
                  )
                  .
                |
                  # A code block
                  \g<code>
                |
                  # An HTML block
                  \g<html>
              )+?
            )
            \n>>>$
          )
      }mx.freeze

      def initialize(text, context = nil, result = nil)
        super text, context, result
        @text = @text.delete("\r")
      end

      def call
        @text.gsub(REGEX) do
          if $~[:quote]
            $~[:quote].gsub(/^/, "> ").gsub(/^> $/, ">")
          else
            $~[0]
          end
        end
      end
    end
  end
end
