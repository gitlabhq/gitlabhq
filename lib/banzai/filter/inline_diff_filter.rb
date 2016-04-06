module Banzai
  module Filter
    class InlineDiffFilter < HTML::Pipeline::Filter
      IGNORED_ANCESTOR_TAGS = %w(pre code tt).to_set

      def call
        search_text_nodes(doc).each do |node|
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)

          content = node.to_html
          content = content.gsub(/(?:\[\-(.*?)\-\]|\{\-(.*?)\-\})/, '<span class="idiff left right deletion">\1\2</span>')
          content = content.gsub(/(?:\[\+(.*?)\+\]|\{\+(.*?)\+\})/, '<span class="idiff left right addition">\1\2</span>')

          next if html == content

          node.replace(content)
        end
        doc
      end
    end
  end
end
