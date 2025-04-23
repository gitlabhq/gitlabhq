# frozen_string_literal: true

module Banzai
  module Filter
    # Filter which extracts top-level paragraph sourcepos, so
    # another processor can determine if it's a quick action. Paragraph source position
    # is returned in `result[:quick_action_paragraphs]`.
    class QuickActionFilter < HTML::Pipeline::Filter
      def call
        result[:quick_action_paragraphs] = []

        # don't use `xpath` as it can take too long
        doc.children.each do |node|
          next unless node.name == 'p'
          next unless node.attributes['data-sourcepos']
          next unless %r{^/}.match?(node.content)

          sourcepos = ::Banzai::Filter::MarkdownFilter.parse_sourcepos(node.attributes['data-sourcepos'].value)

          result[:quick_action_paragraphs] <<
            { start_line: sourcepos[:start][:row], end_line: sourcepos[:end][:row] }
        end

        doc
      end
    end
  end
end
