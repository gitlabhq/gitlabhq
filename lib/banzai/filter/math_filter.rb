require 'uri'

module Banzai
  module Filter
    # HTML filter that adds class="code math" and removes the dolar sign in $`2+2`$.
    #
    class MathFilter < HTML::Pipeline::Filter

      # This picks out $<code>...</code>$.
      # It will return the last $ node
      INLINE_MATH = %Q(descendant-or-self::text()[substring(., string-length(.)) = '$']
        /following-sibling::node()[1][self::code]
        /following-sibling::node()[1][self::text()][starts-with(.,'$')]
      ).freeze

      DISPLAY_MATH = "descendant-or-self::pre[contains(@class, 'math')]".freeze

      STYLE_ATTRIBUTE = 'data-math-style'.freeze


      def call
        doc.xpath(INLINE_MATH).each do |el|
          closing = el
          code = el.previous
          opening = code.previous

          code[:class] = 'code math'
          code[STYLE_ATTRIBUTE] = 'inline'
          closing.content = closing.content[1..-1]
          opening.content = opening.content[0..-2]

          closing
        end

        doc.xpath(DISPLAY_MATH).each do |el|
          el[STYLE_ATTRIBUTE] = 'display'
          el
        end

        doc
      end
    end
  end
end
