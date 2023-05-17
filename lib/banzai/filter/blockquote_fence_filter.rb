# frozen_string_literal: true

module Banzai
  module Filter
    class BlockquoteFenceFilter < TimeoutTextPipelineFilter
      REGEX = %r{
          #{::Gitlab::Regex.markdown_code_or_html_blocks}
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
      }mx.freeze

      def initialize(text, context = nil, result = nil)
        super text, context, result
        @text = @text.delete("\r")
      end

      def call_with_timeout
        @text.gsub(REGEX) do
          if $~[:blockquote]
            # keep the same number of source lines/positions by replacing the
            # fence lines with newlines
            indent = $~[:indent]
            "\n" + $~[:blockquote].gsub(/^#{Regexp.quote(indent)}/, "#{indent}> ").gsub(/^> $/, ">") + "\n"
          else
            $~[0]
          end
        end
      end
    end
  end
end
