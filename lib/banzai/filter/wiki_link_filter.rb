# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that "fixes" links to pages/files in a wiki.
    # Rewrite rules are documented in the `WikiPipeline` spec.
    #
    # Context options:
    #   :project_wiki
    class WikiLinkFilter < HTML::Pipeline::Filter
      include Gitlab::Utils::SanitizeNodeLink

      def call
        return doc unless project_wiki?

        doc.search('a:not(.gfm)').each { |el| process_link(el.attribute('href'), el) }

        doc.search('video').each { |el| process_link(el.attribute('src'), el) }

        doc.search('img').each do |el|
          attr = el.attribute('data-src') || el.attribute('src')

          process_link(attr, el)
        end

        doc
      end

      protected

      def process_link(link_attr, node)
        process_link_attr(link_attr)
        remove_unsafe_links({ node: node }, remove_invalid_links: false)
      end

      def project_wiki?
        !context[:project_wiki].nil?
      end

      def process_link_attr(html_attr)
        return if html_attr.blank?

        html_attr.value = apply_rewrite_rules(html_attr.value)
      rescue URI::Error, Addressable::URI::InvalidURIError
        # noop
      end

      def apply_rewrite_rules(link_string)
        Rewriter.new(link_string, wiki: context[:project_wiki], slug: context[:page_slug]).apply_rules
      end
    end
  end
end
