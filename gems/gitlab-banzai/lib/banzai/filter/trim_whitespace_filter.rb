# frozen_string_literal: true

module Banzai
  module Filter
    # Removes leading and trailing whitespace from the rendered document.
    # Removed elements can leave several adjacent text nodes behind, so each
    # boundary is trimmed until a non-empty node remains.
    class TrimWhitespaceFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      def call
        while (node = doc.children.first)&.text?
          node.content = node.content.lstrip
          break unless node.content.empty?

          node.remove
        end

        while (node = doc.children.last)&.text?
          node.content = node.content.rstrip
          break unless node.content.empty?

          node.remove
        end

        doc
      end
    end
  end
end
