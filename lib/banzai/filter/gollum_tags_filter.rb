# frozen_string_literal: true

module Banzai
  module Filter
    # HTML Filter for parsing Gollum's tags in HTML.
    # Only used for the ascii_doc pipeline or the older cmark parser.
    #
    # It's only parses the following tags:
    #
    #   * [[page name or url]]
    #   * [[link text|page name or url]]
    #
    # - Examples:
    #
    #   * [[Bug Reports]]
    #   * [[How to Contribute|Contributing]]
    #   * [[http://en.wikipedia.org/wiki/Git_(software)]]
    #   * [[Git|http://en.wikipedia.org/wiki/Git_(software)]]
    #   * [[images/logo.png]]
    #
    # Linking to an actual wiki or resources happens in WikiLinkGollumFilter
    class GollumTagsFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      include ActionView::Helpers::TagHelper

      # Pattern to match tags content that should be parsed in HTML.
      # See https://github.com/gollum/gollum/wiki
      #
      # Rubular: http://rubular.com/r/7dQnE5CUCH
      TAGS_PATTERN_UNTRUSTED = '\[\[(.+?)\]\]'
      TAGS_PATTERN_UNTRUSTED_REGEX =
        Gitlab::UntrustedRegexp.new(TAGS_PATTERN_UNTRUSTED, multiline: false).freeze

      # Do not perform linking inside these tags.
      IGNORED_ANCESTOR_TAGS = %w[pre code tt].to_set

      def call
        return doc if MarkdownFilter.glfm_markdown?(context) && context[:pipeline] != :ascii_doc

        doc.xpath('descendant-or-self::text()').each do |node|
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)
          next unless TAGS_PATTERN_UNTRUSTED_REGEX.match?(node.content)

          html = TAGS_PATTERN_UNTRUSTED_REGEX
            .replace_gsub(CGI.escapeHTML(node.content), limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match|
            process_tag(CGI.unescapeHTML(match[1]))&.to_s || match[0]
          end

          node.replace(html)
        end

        doc
      end

      private

      # Process a single tag into its final HTML form.
      #
      # tag - The String tag contents (the stuff inside the double brackets).
      #
      # Returns the String HTML version of the tag.
      def process_tag(tag)
        parts = tag.split('|')
        return if parts.empty?

        if parts.size == 1
          reference = parts[0].strip
        else
          name, reference = *parts.compact.map(&:strip)
        end

        if reference
          sanitized_content_tag(:a, name || reference, href: reference, data: { wikilink: true })
        end
      end

      def sanitized_content_tag(name, content, options = {})
        html = content_tag(name, content, options)
        node = Banzai::Filter::SanitizationFilter.new(html).call
        node = Banzai::Filter::SanitizeLinkFilter.new(node).call

        node&.children&.first
      end
    end
  end
end
