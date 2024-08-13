# frozen_string_literal: true

# TODO: This is now a legacy filter, and is only used with the Ruby parser.
# The current markdown parser now properly handles multiline block quotes.
# The Ruby parser is now only for benchmarking purposes.
# issue: https://gitlab.com/gitlab-org/gitlab/-/issues/454601
module Banzai
  module Filter
    class BlockquoteFenceLegacyFilter < HTML::Pipeline::TextFilter
      MARKDOWN_CODE_BLOCK_REGEX = %r{
        (?<code>
          # Code blocks:
          # ```
          # Anything, including `>>>` blocks which are ignored by this filter
          # ```

          ^```
          .+?
          \n```\ *$
        )
      }mx

      MARKDOWN_HTML_BLOCK_REGEX = %r{
        (?<html>
          # HTML block:
          # <tag>
          # Anything, including `>>>` blocks which are ignored by this filter
          # </tag>

          ^<[^>]+?>\ *\n
          .+?
          \n</[^>]+?>\ *$
        )
      }mx

      MARKDOWN_CODE_OR_HTML_BLOCKS = %r{
          #{MARKDOWN_CODE_BLOCK_REGEX}
        |
          #{MARKDOWN_HTML_BLOCK_REGEX}
      }mx

      REGEX = %r{
          #{MARKDOWN_CODE_OR_HTML_BLOCKS}
        |
          (?=(?<=^\n|\A)\ *>>>\ *\n.*\n\ *>>>\ *(?=\n$|\z))(?:
            # Blockquote:
            # >>>
            # Anything, including code and HTML blocks
            # >>>

            (?<=^\n|\A)(?<indent>\ *)>>>\ *\n
            (?<blockquote>
              (?:
                  # Any character that doesn't introduce a code or HTML block
                  (?!
                      ^```
                    |
                      ^<[^>]+?>\ *\n
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
            \n\ *>>>\ *(?=\n$|\z)
          )
      }mx

      def initialize(text, context = nil, result = nil)
        super text, context, result
      end

      def call
        return @text if MarkdownFilter.glfm_markdown?(context)

        @text.gsub(REGEX) do
          if $~[:blockquote]
            # keep the same number of source lines/positions by replacing the
            # fence lines with newlines
            indent = $~[:indent]
            "\n#{$~[:blockquote].gsub(/^#{Regexp.quote(indent)}/, "#{indent}> ").gsub(/^> $/, '>')}\n"
          else
            $~[0]
          end
        end
      end
    end
  end
end
