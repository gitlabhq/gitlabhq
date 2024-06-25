# frozen_string_literal: true

module Banzai
  module Filter
    # In order to allow a user to short-circuit our reference shortcuts
    # (such as # or !), the user should be able to escape them, like \#.
    # The parser does surround escaped chars with `<span data-escaped-char></span>`
    # which will short-circuit our references. However it does that for all
    # escaped chars.
    # So while a label specified as `~c_bug\_` is valid, our label parsing
    # does not understand `~c_bug<span data-escaped-char>_</span>`
    #
    # This filter strips out any `<span data-escaped-char>` that is not one
    # of our references.
    #
    # TODO: Parsing of references should be fixed to remove need of this filter.
    #       https://gitlab.com/gitlab-org/gitlab/-/issues/457556
    class EscapedCharFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      # Table of characters that need this special handling. It consists of the
      # GitLab special reference characters.
      REFERENCE_CHARS = %w[$ % # & @ ! ~ ^].freeze

      XPATH_ESCAPED_CHAR = Gitlab::Utils::Nokogiri.css_to_xpath('span[data-escaped-char]').freeze

      def call
        return doc unless MarkdownFilter.glfm_markdown?(context)

        remove_unnecessary_escapes

        doc
      end

      private

      def remove_unnecessary_escapes
        doc.xpath(XPATH_ESCAPED_CHAR).each do |node|
          escaped_item = REFERENCE_CHARS.find { |item| item == node.content }

          # Escaped reference character, so leave as is. This is so that our normal
          # reference processing can be short-circuited by escaping the reference,
          # like \@username
          next if escaped_item

          merge_adjacent_text_nodes(node)
        end
      end

      def text_node?(node)
        node.is_a?(Nokogiri::XML::Text)
      end

      # Merge directly adjacent text nodes and replace existing node with
      # the merged content. For example, the document could be
      #   #(Text "~c_bug"), #(Element:0x57724 { name = "span" }, children = [ #(Text "_")] })]
      # Our reference processing requires a single string of text to match against. So even if it was
      #   #(Text "~c_bug"), #(Text "_")
      # it wouldn't match.  Merging together will give
      #   #(Text "~c_bug_")
      def merge_adjacent_text_nodes(node)
        content = CGI.escapeHTML(node.content)

        if text_node?(node.previous)
          content.prepend(node.previous.to_html)
          node.previous.remove
        end

        if text_node?(node.next)
          content.concat(node.next.to_html)
          node.next.remove
        end

        node.replace(content)
      end
    end
  end
end
