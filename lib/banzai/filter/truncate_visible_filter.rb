# frozen_string_literal: true

module Banzai
  module Filter
    class TruncateVisibleFilter < HTML::Pipeline::Filter
      # Truncates the document to `truncate_visible_max_chars` characters,
      # excluding any HTML tags.

      MATCH_CODE = 'pre > code > .line'

      def call
        return doc unless context[:truncate_visible_max_chars].present?

        max_chars = context[:truncate_visible_max_chars]
        content_length = 0
        @truncated = false

        doc.traverse do |node|
          if node.text? || node.content.empty?
            if truncated
              node.remove
              next
            end

            handle_line_breaks(node)
            truncate_content(content_length, max_chars, node)

            content_length += node.content.length
          end

          truncate_if_block(node)
        end

        doc
      end

      private

      attr_reader :truncated

      def truncate_content(content_length, max_chars, node)
        num_remaining = max_chars - content_length
        return unless node.content.length > num_remaining

        node.content = node.content.truncate(num_remaining)
        @truncated = true
      end

      # Handle line breaks within a node
      def handle_line_breaks(node)
        return unless node.content.strip.lines.length > 1

        node.content = "#{node.content.lines.first.chomp}..."
        @truncated = true
      end

      # If `node` is the first block element, and the
      # text hasn't already been truncated, then append "..." to the node contents
      # and return true.  Otherwise return false.
      def truncate_if_block(node)
        return if truncated
        return unless node.element? && (node.description&.block? || node.matches?(MATCH_CODE))

        node.inner_html = "#{node.inner_html}..." if node.next_sibling
        @truncated = true
      end
    end
  end
end
