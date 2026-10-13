# frozen_string_literal: true

# Determines if an <img> tag references media to be embedded in an <iframe>. The administrator
# needs to explicitly allow the provider. A matching <img> is replaced with an inert
# <span class="js-render-iframe"> for the frontend to convert into an <iframe>, along with data-
# attributes describing which provider matched, the URL as literally entered by the user, and the
# URL as converted by the provider. We replace the <img> with an inert tag to avoid the src being
# fetched by the browser before the frontend has had time to replace or remove it.
#
# Even though the src will have been allowed by the administrator, don't insert the <iframe> tag
# here on the backend - allow the frontend to handle it. This allows for the administrator to
# disable the provider in the future and have it stop being rendered immediately, without any bad
# <iframe> tags lingering in the Markdown cache.
module Banzai
  module Filter
    class IframeLinkFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      include Concerns::ContextAccessors

      XPATH = 'descendant-or-self::img[not(ancestor::a)]'

      def call
        return doc unless Gitlab::CurrentSettings.iframe_rendering_enabled?

        return doc unless project&.allow_iframes_in_markdown_feature_flag_enabled? ||
          group&.allow_iframes_in_markdown_feature_flag_enabled?

        doc.xpath(XPATH).each do |img|
          match = ::Gitlab::Markdown::IframeProviders.match(img['src'])
          next unless match

          img.replace(embed_node(img, match))
        end

        doc
      end

      private

      # Builds the embed <span> for the frontend to evaluate.
      #
      # @param img [Nokogiri::XML::Element] the <img> element that matched a provider
      # @param match [Gitlab::Markdown::IframeProviders::Match] the match data from ::Gitlab::Markdown::IframeProviders.match
      # @return [Nokogiri::XML::Element] a <span class="js-render-iframe">, containing a fallback link
      def embed_node(img, match)
        canonical_src = img['src']
        alt = img['alt'].presence

        attrs = {
          class: 'media-container iframe-container js-render-iframe',
          'data-iframe-src' => match.url,
          'data-iframe-canonical-src' => canonical_src,
          'data-iframe-provider-id' => match.provider.id
        }
        attrs['data-title'] = alt if alt
        attrs['data-width'] = img['width'] if img['width']
        attrs['data-height'] = img['height'] if img['height']

        doc.document.create_element('span', attrs).tap do |container|
          container.add_child(doc.document.create_element('a', alt || canonical_src, href: canonical_src))
        end
      end
    end
  end
end
