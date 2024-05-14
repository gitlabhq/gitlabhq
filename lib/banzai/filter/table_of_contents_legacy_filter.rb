# frozen_string_literal: true

require 'cgi/util'

# TODO: This is now a legacy filter, and is only used with the Ruby parser.
# The current markdown parser now properly handles adding anchors to headers.
# The Ruby parser is now only for benchmarking purposes.
# issue: https://gitlab.com/gitlab-org/gitlab/-/issues/454601

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/table_of_contents.js
module Banzai
  module Filter
    # HTML filter that adds an anchor child element to all Headers in a
    # document, so that they can be linked to.
    #
    # Generates the Table of Contents with links to each header. See Results.
    #
    # Based on HTML::Pipeline::TableOfContentsFilter.
    #
    # Context options:
    #   :no_header_anchors - Skips all processing done by this filter.
    #
    # Results:
    #   :toc - String containing Table of Contents data as a `ul` element with
    #          `li` child elements.
    class TableOfContentsLegacyFilter < HTML::Pipeline::Filter
      include Gitlab::Utils::Markdown

      CSS   = 'h1, h2, h3, h4, h5, h6'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        return doc if MarkdownFilter.glfm_markdown?(context)
        return doc if context[:no_header_anchors]

        result[:toc] = +""

        headers = Hash.new(0)
        header_root = current_header = HeaderNode.new

        doc.xpath(XPATH).each do |node|
          header_content = node.children.first
          next unless header_content

          id = string_to_anchor(node.text[0...255])

          uniq = headers[id] > 0 ? "-#{headers[id]}" : ''
          headers[id] += 1
          href = "#{id}#{uniq}"

          current_header = HeaderNode.new(node: node, href: href, previous_header: current_header)

          header_content.add_previous_sibling(anchor_tag(href))
        end

        push_toc(header_root.children, root: true)

        doc
      end

      private

      def anchor_tag(href)
        escaped_href = CGI.escape(href) # account for non-ASCII characters

        <<~TAG.squish
          <a id="#{Banzai::Renderer::USER_CONTENT_ID_PREFIX}#{href}"
          class="anchor" href="##{escaped_href}" aria-hidden="true"></a>
        TAG
      end

      def push_toc(children, root: false)
        return if children.empty?

        klass = ' class="section-nav"' if root

        result[:toc] << "<ul#{klass}>"
        children.each { |child| push_anchor(child) }
        result[:toc] << '</ul>'
      end

      def push_anchor(header_node)
        result[:toc] << %(<li><a href="##{header_node.href}">#{header_node.text}</a>)
        push_toc(header_node.children)
        result[:toc] << '</li>'
      end

      class HeaderNode
        attr_reader :node, :href, :parent, :children

        def initialize(node: nil, href: nil, previous_header: nil)
          @node = node
          @href = CGI.escape(href) if href
          @children = []

          @parent = find_parent(previous_header)
          @parent.children.push(self) if @parent
        end

        def level
          return 0 unless node

          @level ||= node.name[1].to_i
        end

        def text
          return '' unless node

          @text ||= CGI.escapeHTML(node.text)
        end

        private

        def find_parent(previous_header)
          return unless previous_header

          if level == previous_header.level
            parent = previous_header.parent
          elsif level > previous_header.level
            parent = previous_header
          else
            parent = previous_header
            parent = parent.parent while parent.level >= level
          end

          parent
        end
      end
    end
  end
end
