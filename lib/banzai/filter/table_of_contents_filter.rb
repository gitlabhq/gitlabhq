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
      HeaderNode = Struct.new(:level, :href, :text, :children, :parent)

      def call
        return doc if context[:no_header_anchors]

        result[:toc] = ""

        headers = Hash.new(0)

        # root node of header-tree
        header_root = HeaderNode.new(0, nil, nil, [], nil)
        current_header = header_root

        doc.css('h1, h2, h3, h4, h5, h6').each do |node|
          text = node.text

          id = text.downcase
          id.gsub!(PUNCTUATION_REGEXP, '') # remove punctuation
          id.tr!(' ', '-') # replace spaces with dash
          id.squeeze!('-') # replace multiple dashes with one

          uniq = (headers[id] > 0) ? "-#{headers[id]}" : ''
          headers[id] += 1

          if header_content = node.children.first
            # namespace detection will be automatically handled via javascript (see issue #22781)
            namespace = "user-content-"
            href = "#{id}#{uniq}"

            level = node.name[1].to_i # get this header level
            if level == current_header.level
              # same as previous
              parent = current_header.parent
            elsif level > current_header.level
              # larger (weaker) than previous
              parent = current_header
            else
              # smaller (stronger) than previous
              # search parent
              parent = current_header
              parent = parent.parent while parent.level >= level
            end

            # create header-node and push as child
            header_node = HeaderNode.new(level, href, text, [], parent)
            parent.children.push(header_node)
            current_header = header_node

            header_content.add_previous_sibling(anchor_tag("#{namespace}#{href}", href))
          end
        end

        # extract header-tree
        if header_root.children.length > 0
          result[:toc] = %Q{<ul class="section-nav">\n}
          header_root.children.each do |child|
            push_toc(child)
          end
          result[:toc] << '</ul>'
        end

        doc
      end

      private

      def anchor_tag(id, href)
        %Q{<a id="#{id}" class="anchor" href="##{href}" aria-hidden="true"></a>}
      end

      def push_toc(header_node)
        result[:toc] << %Q{<li><a href="##{header_node.href}">#{header_node.text}</a>}
        if header_node.children.length > 0
          result[:toc] << '<ul>'
          header_node.children.each do |child|
            push_toc(child)
          end
          result[:toc] << '</ul>'
        end
        result[:toc] << '</li>\n'
      end
    end
  end
end
