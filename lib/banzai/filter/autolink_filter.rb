# frozen_string_literal: true

require 'uri'

# This filter handles autolinking when a pipeline does not
# use the MarkdownFilter, which handles it's own autolinking.
# This happens in particular for the SingleLinePipeline and the
# CommitDescriptionPipeline.
#
# rubocop:disable Rails/OutputSafety -- this is legacy/unused, no need fixing.
# rubocop:disable Gitlab/NoCodeCoverageComment -- no coverage needed for a legacy filter
# :nocov: undercoverage
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
      include Gitlab::Utils::SanitizeNodeLink

      # Pattern to match text that should be autolinked.
      #
      # A URI scheme begins with a letter and may contain letters, numbers,
      # plus, period and hyphen. Schemes are case-insensitive but we're being
      # picky here and allowing only lowercase for autolinks.
      #
      # See http://en.wikipedia.org/wiki/URI_scheme
      #
      # The negative lookbehind ensures that users can paste a URL followed by
      # punctuation without those characters being included in the generated
      # link. It matches the behaviour of Rinku 2.0.1:
      # https://github.com/vmg/rinku/blob/v2.0.1/ext/rinku/autolink.c#L65
      #
      # Rubular: https://rubular.com/r/M2sruz0iNaUxDA
      # Note that it's not possible to use Gitlab::UntrustedRegexp for LINK_PATTERN,
      # as `(?<!` is unsupported in `re2`, see https://github.com/google/re2/wiki/Syntax
      LINK_PATTERN = %r{([a-z][a-z0-9\+\.-]{1,30}://[^\s>]{1,2000})(?<!\?|!|\.|,|:)}

      ENTITY_UNTRUSTED = '((?:&[\w#]+;)+)\z'
      ENTITY_UNTRUSTED_REGEX = Gitlab::UntrustedRegexp.new(ENTITY_UNTRUSTED, multiline: false)

      # Text matching LINK_PATTERN inside these elements will not be linked
      IGNORE_PARENTS = %w[a code kbd pre script style].to_set

      # The XPath query to use for finding text nodes to parse.
      TEXT_QUERY = %(descendant-or-self::text()[
        not(#{IGNORE_PARENTS.map { |p| "ancestor::#{p}" }.join(' or ')})
        and contains(., '://')
      ]).freeze

      PUNCTUATION_PAIRS = {
        "'" => "'",
        '"' => '"',
        ')' => '(',
        ']' => '[',
        '}' => '{'
      }.freeze

      def call
        if MarkdownFilter.glfm_markdown?(context) &&
            context[:pipeline] != :single_line &&
            context[:pipeline] != :commit_description
          return doc
        end

        return doc if context[:autolink] == false

        doc.xpath(TEXT_QUERY).each do |node|
          content = node.to_html

          next unless content.match(LINK_PATTERN)

          html = autolink_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      private

      def autolink_match(match)
        # start by stripping out dangerous links
        begin
          uri = Addressable::URI.parse(match)
          return match unless safe_protocol?(uri.scheme)
        rescue Addressable::URI::InvalidURIError
          return match
        end

        # Remove any trailing HTML entities and store them for appending
        # outside the link element. The entity must be marked HTML safe in
        # order to be output literally rather than escaped.
        dropped = ''
        match = ENTITY_UNTRUSTED_REGEX.replace_gsub(match) do |entities|
          dropped = entities[1].html_safe

          ''
        end

        # To match the behavior of Rinku, if the matched link ends with a
        # closing part of a matched pair of punctuation, we remove that trailing
        # character unless there are an equal number of closing and opening
        # characters in the link.
        if match.end_with?(*PUNCTUATION_PAIRS.keys)
          close_character = match[-1]
          close_count = match.count(close_character)
          open_character = PUNCTUATION_PAIRS[close_character]
          open_count = match.count(open_character)

          if open_count != close_count || open_character == close_character
            dropped += close_character
            match = match[0..-2]
          end
        end

        # Since this came from a Text node, make sure the new href is encoded.
        # `commonmarker` percent encodes the domains of links it handles, so
        # do the same (instead of using `normalized_encode`).
        begin
          href_safe = Addressable::URI.encode(match).html_safe
        rescue Addressable::URI::InvalidURIError
          return uri.to_s
        end

        html_safe_match = match.html_safe
        options         = link_options.merge(href: href_safe)

        content_tag(:a, html_safe_match, options) + dropped
      end

      def autolink_filter(text)
        Gitlab::StringRegexMarker.new(CGI.unescapeHTML(text), text.html_safe)
          .mark(LINK_PATTERN) do |link, _left, _right, _mode|
            autolink_match(link).html_safe
          end
      end

      def link_options
        @link_options ||= context[:link_attr] || {}
      end
    end
  end
end
# :nocov:
# rubocop:enable Gitlab/NoCodeCoverageComment
# rubocop:enable Rails/OutputSafety
