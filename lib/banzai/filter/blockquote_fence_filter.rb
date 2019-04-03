# frozen_string_literal: true

module Banzai
  module Filter
    class BlockquoteFenceFilter < HTML::Pipeline::TextFilter
      REGEX = %r{
          #{::Gitlab::Regex.markdown_code_or_html_blocks}
        |
          (?:
            # Blockquote:
            # >>>
            # Anything, including code and HTML blocks
            # >>>

            ^>>>\ *\n
            (?<quote>
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
            \n>>>\ *$
          )
      }mx.freeze

      def initialize(text, context = nil, result = nil)
        super text, context, result
        @text = @text.delete("\r")
      end

      def call
        @text.gsub(REGEX) do
          if $~[:quote]
            # keep the same number of source lines/positions by replacing the
            # fence lines with newlines
            "\n" + $~[:quote].gsub(/^/, "> ").gsub(/^> $/, ">") + "\n"
          else
            $~[0]
          end
        end
      end
    end
  end
end
