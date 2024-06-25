# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that "fixes" links to pages/files in a wiki.
    # Rewrite rules are documented in the `WikiPipeline` spec.
    #
    # Context options:
    #   :wiki
    class WikiLinkFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      include Gitlab::Utils::SanitizeNodeLink

      CSS_A     = 'a:not(.gfm)'
      XPATH_A   = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_A).freeze
      CSS_VA    = 'video, audio'
      XPATH_VA  = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_VA).freeze
      CSS_IMG   = 'img'
      XPATH_IMG = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_IMG).freeze

      def call
        return doc unless wiki?

        doc.xpath(XPATH_A).each { |el| process_link(el.attribute('href'), el) }

        doc.xpath(XPATH_VA).each { |el| process_link(el.attribute('src'), el) }

        doc.xpath(XPATH_IMG).each do |el|
          attr = el.attribute('data-src') || el.attribute('src')

          process_link(attr, el)
        end

        doc
      end

      protected

      def process_link(link_attr, node)
        process_link_attr(link_attr, node)
        remove_unsafe_links({ node: node }, remove_invalid_links: false)
      end

      def wiki?
        !context[:wiki].nil?
      end

      def process_link_attr(html_attr, node)
        return if html_attr.blank?

        rewritten_value = apply_rewrite_rules(html_attr.value)

        if html_attr.value != rewritten_value
          preserve_original_link(html_attr, node)
        end

        html_attr.value = rewritten_value
      rescue URI::Error, Addressable::URI::InvalidURIError
        # noop
      end

      def preserve_original_link(html_attr, node)
        return if html_attr.blank?
        return if node.value?('data-canonical-src')

        node.set_attribute('data-canonical-src', html_attr.value)
      end

      def apply_rewrite_rules(link_string)
        Rewriter.new(link_string, wiki: context[:wiki], slug: context[:page_slug]).apply_rules
      end
    end
  end
end
