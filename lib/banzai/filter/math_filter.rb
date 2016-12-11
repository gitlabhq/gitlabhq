require 'uri'

module Banzai
  module Filter
    # HTML filter that adds class="code math" and removes the dolar sign in $`2+2`$.
    #
    class MathFilter < HTML::Pipeline::Filter
      # This picks out <code>...</code>.
      INLINE_MATH = 'descendant-or-self::code'.freeze

      DISPLAY_MATH = "descendant-or-self::pre[contains(@class, 'math') and contains(@class, 'code')]".freeze

      STYLE_ATTRIBUTE = 'data-math-style'.freeze

      TAG_CLASS = 'js-render-math'.freeze

      DOLLAR_SIGN = '$'.freeze

      def call
        doc.xpath(INLINE_MATH).each do |el|
          code = el
          closing = code.next
          opening = code.previous

          if (!closing.nil? and closing.content[0] == DOLLAR_SIGN) \
             and (!opening.nil? and opening.content[-1] == DOLLAR_SIGN)

            code[:class] = 'code math ' << TAG_CLASS
            code[STYLE_ATTRIBUTE] = 'inline'
            closing.content = closing.content[1..-1]
            opening.content = opening.content[0..-2]
          end
          code
        end

        doc.xpath(DISPLAY_MATH).each do |el|
          el[STYLE_ATTRIBUTE] = 'display'
          el[:class] = el[:class] << ' ' << TAG_CLASS
          el
        end

        doc
      end
    end
  end
end
