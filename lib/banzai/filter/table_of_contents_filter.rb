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
    class TableOfContentsFilter < HTML::Pipeline::Filter
      PUNCTUATION_REGEXP = /[^\p{Word}\- ]/u

      def call
        return doc if context[:no_header_anchors]

        result[:toc] = ""

        headers = Hash.new(0)
        header_root = current_header = HeaderNode.new

        doc.css('h1, h2, h3, h4, h5, h6').each do |node|
          if header_content = node.children.first
            id = node
              .text
              .downcase
              .gsub(PUNCTUATION_REGEXP, '') # remove punctuation
              .tr(' ', '-') # replace spaces with dash
              .squeeze('-') # replace multiple dashes with one
              .gsub(/\A(\d+)\z/, 'anchor-\1') # digits-only hrefs conflict with issue refs

            uniq = headers[id] > 0 ? "-#{headers[id]}" : ''
            headers[id] += 1
            href = "#{id}#{uniq}"

            current_header = HeaderNode.new(node: node, href: href, previous_header: current_header)

            header_content.add_previous_sibling(anchor_tag(href))
          end
        end

        push_toc(header_root.children, root: true)

        doc
      end

      private

      def anchor_tag(href)
        %Q{<a id="user-content-#{href}" class="anchor" href="##{href}" aria-hidden="true"></a>}
      end

      def push_toc(children, root: false)
        return if children.empty?

        klass = ' class="section-nav"' if root

        result[:toc] << "<ul#{klass}>"
        children.each { |child| push_anchor(child) }
        result[:toc] << '</ul>'
      end

      def push_anchor(header_node)
        result[:toc] << %Q{<li><a href="##{header_node.href}">#{header_node.text}</a>}
        push_toc(header_node.children)
        result[:toc] << '</li>'
      end

      class HeaderNode
        attr_reader :node, :href, :parent, :children

        def initialize(node: nil, href: nil, previous_header: nil)
          @node = node
          @href = href
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

          @text ||= node.text
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
