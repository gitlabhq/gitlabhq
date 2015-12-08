require 'gitlab/markdown'
require 'html/pipeline/filter'
require 'uri'

module Gitlab
  module Markdown
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
      LINK_PATTERN = %r{([a-z][a-z0-9\+\.-]+://\S+)(?<!,|\.)}

      # Text matching LINK_PATTERN inside these elements will not be linked
      IGNORE_PARENTS = %w(a code kbd pre script style).to_set

      def call
        return doc if context[:autolink] == false

        rinku_parse
        text_parse
      end

      private

      # Run the text through Rinku as a first pass
      #
      # This will quickly autolink http(s) and ftp links.
      #
      # `@doc` will be re-parsed with the HTML String from Rinku.
      def rinku_parse
        # Convert the options from a Hash to a String that Rinku expects
        options = tag_options(link_options)

        # NOTE: We don't parse email links because it will erroneously match
        # external Commit and CommitRange references.
        #
        # The final argument tells Rinku to link short URLs that don't include a
        # period (e.g., http://localhost:3000/)
        rinku = Rinku.auto_link(html, :urls, options, IGNORE_PARENTS.to_a, 1)

        # Rinku returns a String, so parse it back to a Nokogiri::XML::Document
        # for further processing.
        @doc = parse_html(rinku)
      end

      # Autolinks any text matching LINK_PATTERN that Rinku didn't already
      # replace
      def text_parse
        search_text_nodes(doc).each do |node|
          content = node.to_html

          next if has_ancestor?(node, IGNORE_PARENTS)
          next unless content.match(LINK_PATTERN)

          # If Rinku didn't link this, there's probably a good reason, so we'll
          # skip it too
          next if content.start_with?(*%w(http https ftp))

          html = autolink_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      def autolink_filter(text)
        text.gsub(LINK_PATTERN) do |match|
          # Remove any trailing HTML entities and store them for appending
          # outside the link element. The entity must be marked HTML safe in
          # order to be output literally rather than escaped.
          match.gsub!(/((?:&[\w#]+;)+)\z/, '')
          dropped = ($1 || '').html_safe

          options = link_options.merge(href: match)
          content_tag(:a, match, options) + dropped
        end
      end

      def link_options
        @link_options ||= context[:link_attr] || {}
      end
    end
  end
end
