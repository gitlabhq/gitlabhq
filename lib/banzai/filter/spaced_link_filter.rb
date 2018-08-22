# frozen_string_literal: true

require 'uri'

module Banzai
  module Filter
    # HTML Filter for markdown links with spaces in the URLs
    #
    # Based on Banzai::Filter::AutolinkFilter
    #
    # CommonMark does not allow spaces in the url portion of a link.
    # For example, `[example](page slug)` is not valid.  However,
    # in our wikis, we support (via RedCarpet) this type of link, allowing
    # wiki pages to be easily linked by their title.  This filter adds that functionality.
    # The intent is for this to only be used in Wikis - in general, we want
    # to adhere to CommonMark's spec.
    #
    class SpacedLinkFilter < HTML::Pipeline::Filter
      include ActionView::Helpers::TagHelper

      # Pattern to match a standard markdown link
      #
      # Rubular: http://rubular.com/r/z9EAHxYmKI
      LINK_PATTERN = /\[([^\]]+)\]\(([^)"]+)(?: \"([^\"]+)\")?\)/

      # Text matching LINK_PATTERN inside these elements will not be linked
      IGNORE_PARENTS = %w(a code kbd pre script style).to_set

      # The XPath query to use for finding text nodes to parse.
      TEXT_QUERY = %Q(descendant-or-self::text()[
        not(#{IGNORE_PARENTS.map { |p| "ancestor::#{p}" }.join(' or ')})
        and contains(., ']\(')
      ]).freeze

      def call
        return doc if context[:markdown_engine] == :redcarpet

        doc.xpath(TEXT_QUERY).each do |node|
          content = node.to_html

          next unless content.match(LINK_PATTERN)

          html = spaced_link_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      private

      def spaced_link_match(link)
        match = LINK_PATTERN.match(link)
        return link unless match && match[1] && match[2]

        # escape the spaces in the url so that it's a valid markdown link,
        # then run it through the markdown processor again, let it do its magic
        text     = match[1]
        new_link = match[2].gsub(' ', '%20')
        title    = match[3] ? " \"#{match[3]}\"" : ''
        html     = Banzai::Filter::MarkdownFilter.call("[#{text}](#{new_link}#{title})", context)

        # link is wrapped in a <p>, so strip that off
        html.sub('<p>', '').chomp('</p>')
      end

      def spaced_link_filter(text)
        Gitlab::StringRegexMarker.new(CGI.unescapeHTML(text), text.html_safe).mark(LINK_PATTERN) do |link, left:, right:|
          spaced_link_match(link)
        end
      end
    end
  end
end
