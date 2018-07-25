# frozen_string_literal: true

require 'uri'

module Banzai
  module Filter
    # HTML filter that "fixes" links to pages/files in a wiki.
    # Rewrite rules are documented in the `WikiPipeline` spec.
    #
    # Context options:
    #   :project_wiki
    class WikiLinkFilter < HTML::Pipeline::Filter
      def call
        return doc unless project_wiki?

        doc.search('a:not(.gfm)').each do |el|
          process_link_attr el.attribute('href')
        end

        doc
      end

      protected

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
