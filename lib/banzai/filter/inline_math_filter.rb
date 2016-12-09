require 'uri'

module Banzai
  module Filter
    # HTML filter that adds class="code math" and removes the dolar sign in $`2+2`$.
    #
    class InlineMathFilter < HTML::Pipeline::Filter
      def call
        doc.xpath("descendant-or-self::text()[substring(., string-length(.)) = '$']"\
        '/following-sibling::node()[1][self::code]'\
        "/following-sibling::node()[1][self::text()][starts-with(.,'$')]").each do |el|
          closing = el
          code = el.previous
          opening = code.previous

          code[:class] = 'code math'
          code["data-math-style"] = 'inline'
          closing.content = closing.content[1..-1]
          opening.content = opening.content[0..-2]

          closing
        end

        doc.xpath("descendant-or-self::pre[contains(@class, 'math')]").each do |el|
          # http://stackoverflow.com/questions/4841238/add-a-class-to-an-element-with-nokogiri
          el["data-math-style"] = 'display'
          el
        end

        doc
      end
    end
  end
end
