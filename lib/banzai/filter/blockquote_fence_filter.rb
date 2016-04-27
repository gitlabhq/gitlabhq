module Banzai
  module Filter
    class BlockquoteFenceFilter < HTML::Pipeline::TextFilter
      REGEX = %r{
          (?<code>
            # Code blocks:
            # ```
            # Anything, including ignored `>>>` blocks
            # ```
            ^```.+?\n```$
          )
        |
          (?<html>
            # HTML:
            # <tag>
            # Anything, including ignored `>>>` blocks
            # </tag>
            ^<[^>]+?>.+?\n<\/[^>]+?>$
          )
        |
          (
            ^>>>\n(?<quote>
              (?:
                  (?!^```|^<[^>]+?>).
                |
                  \g<code>
                |
                  \g<html>
              )
            +?)\n>>>$
          )
      }mx.freeze

      def initialize(text, context = nil, result = nil)
        super text, context, result
        @text = @text.delete "\r"
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
