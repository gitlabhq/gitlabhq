require 'html/pipeline/filter'

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

        doc.css('h1, h2, h3, h4, h5, h6').each do |node|
          text = node.text

          id = text.downcase
          id.gsub!(PUNCTUATION_REGEXP, '') # remove punctuation
          id.tr!(' ', '-') # replace spaces with dash
          id.squeeze!('-') # replace multiple dashes with one

          uniq = (headers[id] > 0) ? "-#{headers[id]}" : ''
          headers[id] += 1

          if header_content = node.children.first
            href = "#{id}#{uniq}"
            push_toc(href, text)
            header_content.add_previous_sibling(anchor_tag(href))
          end
        end

        result[:toc] = %Q{<ul class="section-nav">\n#{result[:toc]}</ul>} unless result[:toc].empty?

        doc
      end

      private

      def anchor_tag(href)
        %Q{<a id="#{href}" class="anchor" href="##{href}" aria-hidden="true"></a>}
      end

      def push_toc(href, text)
        result[:toc] << %Q{<li><a href="##{href}">#{text}</a></li>\n}
      end
    end
  end
end
