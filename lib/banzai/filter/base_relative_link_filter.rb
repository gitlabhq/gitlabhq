# frozen_string_literal: true

require 'uri'

module Banzai
  module Filter
    class BaseRelativeLinkFilter < HTML::Pipeline::Filter
      include Gitlab::Utils::StrongMemoize
      include Concerns::ContextAccessors

      CSS   = 'a:not(.gfm), img:not(.gfm), video:not(.gfm), audio:not(.gfm)'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      protected

      def linkable_attributes
        # Nokorigi Nodeset#search performs badly for documents with many nodes
        #
        # Here we store fetched attributes in the shared variable "result"
        # This variable is passed through the chain of filters and can be
        # accessed by them
        result[:linkable_attributes] ||= fetch_linkable_attributes
      end

      def relative_url_root
        Gitlab.config.gitlab.relative_url_root.presence || '/'
      end

      def preserve_original_link(html_attr, node)
        return if html_attr.blank?
        return if node.key?('data-canonical-src')

        node.set_attribute('data-canonical-src', html_attr.value)
      end

      private

      def unescape_and_scrub_uri(uri)
        Addressable::URI.unescape(uri).scrub.delete("\0")
      end

      def fetch_linkable_attributes
        attrs = []

        attrs += doc.xpath(XPATH).flat_map do |el|
          [el.attribute('href'), el.attribute('src'), el.attribute('data-src')]
        end

        attrs.reject { |attr| attr.blank? || attr.value.start_with?('//') }
      end
    end
  end
end
