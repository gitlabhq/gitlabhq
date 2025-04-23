# frozen_string_literal: true

module Banzai
  module Filter
    # Filter which looks for possible paragraphs with quick action lines, and allows
    # another processor to do final determination. Paragraph source position
    # is returned in `result[:quick_action_paragraphs]`.
    class QuickActionFilter < HTML::Pipeline::Filter
      def call
        result[:quick_action_paragraphs] = []

        doc.children.xpath('self::p').each do |node|
          next unless node.attributes['data-sourcepos']

          sourcepos = ::Banzai::Filter::MarkdownFilter.parse_sourcepos(node.attributes['data-sourcepos'].value)

          node.children.xpath('self::text()').each do |text_node|
            next unless %r{^/}.match?(text_node.content)

            result[:quick_action_paragraphs] <<
              { start_line: sourcepos[:start][:row], end_line: sourcepos[:end][:row] }
            break
          end
        end

        doc
      end
    end
  end
end
