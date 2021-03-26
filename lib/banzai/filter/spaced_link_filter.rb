# frozen_string_literal: true

require 'uri'

module Banzai
  module Filter
    # HTML Filter for markdown links with spaces in the URLs
    #
    # Based on Banzai::Filter::AutolinkFilter
    #
    # CommonMark does not allow spaces in the url portion of a link/url.
    # For example, `[example](page slug)` is not valid.
    # Neither is `![example](test image.jpg)`. However, particularly
    # in our wikis, we support (via RedCarpet) this type of link, allowing
    # wiki pages to be easily linked by their title.  This filter adds that functionality.
    #
    # This is a small extension to the CommonMark spec.  If they start allowing
    # spaces in urls, we could then remove this filter.
    #
    # Note: Filter::SanitizationFilter should always be run sometime after this filter
    # to prevent XSS attacks
    #
    class SpacedLinkFilter < HTML::Pipeline::Filter
      include ActionView::Helpers::TagHelper

      # Pattern to match a standard markdown link
      #
      # Rubular: http://rubular.com/r/2EXEQ49rg5
      LINK_OR_IMAGE_PATTERN = %r{
        (?<preview_operator>!)?
        \[(?<text>.+?)\]
        \(
          (?<new_link>.+?)
          (?<title>\ ".+?")?
        \)
      }x.freeze

      # Text matching LINK_OR_IMAGE_PATTERN inside these elements will not be linked
      IGNORE_PARENTS = %w(a code kbd pre script style).to_set

      # The XPath query to use for finding text nodes to parse.
      TEXT_QUERY = %Q(descendant-or-self::text()[
        not(#{IGNORE_PARENTS.map { |p| "ancestor::#{p}" }.join(' or ')})
        and contains(., ']\(')
      ])

      def call
        doc.xpath(TEXT_QUERY).each do |node|
          content = node.to_html

          next unless content.match(LINK_OR_IMAGE_PATTERN)

          html = spaced_link_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      private

      def spaced_link_match(link)
        match = LINK_OR_IMAGE_PATTERN.match(link)
        return link unless match

        # escape the spaces in the url so that it's a valid markdown link,
        # then run it through the markdown processor again, let it do its magic
        html = Banzai::Filter::MarkdownFilter.call(transform_markdown(match), context)

        # link is wrapped in a <p>, so strip that off
        p_node = Nokogiri::HTML.fragment(html).at_css('p')
        p_node ? p_node.children.to_html : html
      end

      def spaced_link_filter(text)
        Gitlab::StringRegexMarker.new(CGI.unescapeHTML(text), text.html_safe).mark(LINK_OR_IMAGE_PATTERN) do |link, left:, right:, mode:|
          spaced_link_match(link).html_safe
        end
      end

      def transform_markdown(match)
        preview_operator, text, new_link, title = process_match(match)

        "#{preview_operator}[#{text}](#{new_link}#{title})"
      end

      def process_match(match)
        [
          match[:preview_operator],
          match[:text],
          match[:new_link].gsub(' ', '%20'),
          match[:title]
        ]
      end
    end
  end
end
