require 'uri'

module Banzai
  module Filter
    # HTML filter that adds class="code math" and removes the dollar sign in $`2+2`$.
    #
    class MathFilter < HTML::Pipeline::Filter
      # This picks out <code>...</code>.
      INLINE_MATH = 'descendant-or-self::code'.freeze

      # Pick out a code block which is declared math
      DISPLAY_MATH = "descendant-or-self::pre[contains(@class, 'math') and contains(@class, 'code')]".freeze

      # Attribute indicating inline or display math.
      STYLE_ATTRIBUTE = 'data-math-style'.freeze

      # Class used for tagging elements that should be rendered
      TAG_CLASS = 'js-render-math'.freeze

      INLINE_CLASSES = "code math #{TAG_CLASS}".freeze

      DOLLAR_SIGN = '$'.freeze

      def call
        doc.xpath(INLINE_MATH).each do |code|
          closing = code.next
          opening = code.previous

          # We need a sibling before and after.
          # They should end and start with $ respectively.
          if closing && opening &&
              closing.content.first == DOLLAR_SIGN &&
              opening.content.last == DOLLAR_SIGN

            code[:class] = INLINE_CLASSES
            code[STYLE_ATTRIBUTE] = 'inline'
            closing.content = closing.content[1..-1]
            opening.content = opening.content[0..-2]
          end
        end

        doc.xpath(DISPLAY_MATH).each do |el|
          el[STYLE_ATTRIBUTE] = 'display'
          el[:class] += " #{TAG_CLASS}"
        end

        doc
      end
    end
  end
end
