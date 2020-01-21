# frozen_string_literal: true

require 'uri'

module Banzai
  module Filter
    class BaseRelativeLinkFilter < HTML::Pipeline::Filter
      include Gitlab::Utils::StrongMemoize

      protected

      def linkable_attributes
        strong_memoize(:linkable_attributes) do
          attrs = []

          attrs += doc.search('a:not(.gfm)').map do |el|
            el.attribute('href')
          end

          attrs += doc.search('img:not(.gfm), video:not(.gfm), audio:not(.gfm)').flat_map do |el|
            [el.attribute('src'), el.attribute('data-src')]
          end

          attrs.reject do |attr|
            attr.blank? || attr.value.start_with?('//')
          end
        end
      end

      def relative_url_root
        Gitlab.config.gitlab.relative_url_root.presence || '/'
      end

      def project
        context[:project]
      end

      private

      def unescape_and_scrub_uri(uri)
        Addressable::URI.unescape(uri).scrub
      end
    end
  end
end
