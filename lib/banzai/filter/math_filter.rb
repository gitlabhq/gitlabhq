# frozen_string_literal: true

require 'uri'

# Generated HTML is transformed back to GFM by:
# - app/assets/javascripts/behaviors/markdown/marks/math.js
# - app/assets/javascripts/behaviors/markdown/nodes/code_block.js
module Banzai
  module Filter
    # HTML filter that adds class="code math" and removes the dollar sign in $`2+2`$.
    #
    class MathFilter < HTML::Pipeline::Filter
      # Attribute indicating inline or display math.
      STYLE_ATTRIBUTE = 'data-math-style'

      # Class used for tagging elements that should be rendered
      TAG_CLASS = 'js-render-math'

      INLINE_CLASSES = "code math #{TAG_CLASS}"

      DOLLAR_SIGN = '$'

      def call
        doc.css('code').each do |code|
          closing = code.next
          opening = code.previous

          # We need a sibling before and after.
          # They should end and start with $ respectively.
          if closing && opening &&
              closing.text? && opening.text? &&
              closing.content.first == DOLLAR_SIGN &&
              opening.content.last == DOLLAR_SIGN

            code[:class] = INLINE_CLASSES
            code[STYLE_ATTRIBUTE] = 'inline'
            closing.content = closing.content[1..-1]
            opening.content = opening.content[0..-2]
          end
        end

        doc.css('pre.code.math').each do |el|
          el[STYLE_ATTRIBUTE] = 'display'
          el[:class] += " #{TAG_CLASS}"
        end

        doc
      end
    end
  end
end
