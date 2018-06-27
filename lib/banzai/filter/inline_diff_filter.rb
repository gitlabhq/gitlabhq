module Banzai
  module Filter
    class InlineDiffFilter < HTML::Pipeline::Filter
      IGNORED_ANCESTOR_TAGS = %w(pre code tt).to_set

      def call
        doc.search(".//text()").each do |node|
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)

          content = node.to_html
          html_content = inline_diff_filter(content)

          next if content == html_content

          node.replace(html_content)
        end
        doc
      end

      def inline_diff_filter(text)
        html_content = text.gsub(/(?:\[\-(.*?)\-\]|\{\-(.*?)\-\})/, '<span class="idiff left right deletion">\1\2</span>')
        html_content.gsub(/(?:\[\+(.*?)\+\]|\{\+(.*?)\+\})/, '<span class="idiff left right addition">\1\2</span>')
      end
    end
  end
end
