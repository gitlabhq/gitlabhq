require 'uri'

module Banzai
  module Filter
    # HTML Filter for auto-linking URLs in HTML.
    #
    # Based on HTML::Pipeline::AutolinkFilter
    #
    # Context options:
    #   :autolink  - Boolean, skips all processing done by this filter when false
    #   :link_attr - Hash of attributes for the generated links
    #
    class AutolinkFilter < HTML::Pipeline::Filter
      include ActionView::Helpers::TagHelper

      # Pattern to match text that should be autolinked.
      #
      # A URI scheme begins with a letter and may contain letters, numbers,
      # plus, period and hyphen. Schemes are case-insensitive but we're being
      # picky here and allowing only lowercase for autolinks.
      #
      # See http://en.wikipedia.org/wiki/URI_scheme
      #
      # The negative lookbehind ensures that users can paste a URL followed by a
      # period or comma for punctuation without those characters being included
      # in the generated link.
      #
      # Rubular: http://rubular.com/r/cxjPyZc7Sb
      LINK_PATTERN = %r{([a-z][a-z0-9\+\.-]+://[^\s>]+)(?<!,|\.)}

      # Text matching LINK_PATTERN inside these elements will not be linked
      IGNORE_PARENTS = %w(a code kbd pre script style).to_set

      # The XPath query to use for finding text nodes to parse.
      TEXT_QUERY = %Q(descendant-or-self::text()[
        not(#{IGNORE_PARENTS.map { |p| "ancestor::#{p}" }.join(' or ')})
        and contains(., '://')
      ]).freeze

      def call
        return doc if context[:autolink] == false

        text_parse
      end

      private

      # Return true if any of the UNSAFE_PROTOCOLS strings are included in the URI scheme
      def contains_unsafe?(scheme)
        return false unless scheme

        scheme = scheme.strip.downcase
        Banzai::Filter::SanitizationFilter::UNSAFE_PROTOCOLS.any? { |protocol| scheme.include?(protocol) }
      end

      def text_parse
        doc.xpath(TEXT_QUERY).each do |node|
          content = node.to_html

          next unless content.match(LINK_PATTERN)

          html = autolink_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      def autolink_match(match)
        # start by stripping out dangerous links
        begin
          uri = Addressable::URI.parse(match)
          return match if contains_unsafe?(uri.scheme)
        rescue Addressable::URI::InvalidURIError
          return match
        end

        # Remove any trailing HTML entities and store them for appending
        # outside the link element. The entity must be marked HTML safe in
        # order to be output literally rather than escaped.
        match.gsub!(/((?:&[\w#]+;)+)\z/, '')
        dropped = ($1 || '').html_safe

        options = link_options.merge(href: match)
        content_tag(:a, match.html_safe, options) + dropped
      end

      def autolink_filter(text)
        Gitlab::StringRegexMarker.new(CGI.unescapeHTML(text), text.html_safe).mark(LINK_PATTERN) do |link, left:, right:|
          autolink_match(link)
        end
      end

      def link_options
        @link_options ||= context[:link_attr] || {}
      end
    end
  end
end
