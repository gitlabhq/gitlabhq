# frozen_string_literal: true

# Determines if an <img> tag references media to be embedded in an <iframe>. The administrator
# needs to explicitly allow the provider. The `js-render-iframe` class will get added to allow the
# frontend to convert into an <iframe>, along with data- attributes describing which provider
# matched, and the URL as literally entered by the user. `src` is rewritten to the URL the provider
# uses for embeds, which may differ from the input.
#
# Even though the src will have been allowed by the administrator, don't insert the <iframe> tag
# here on the backend - allow the frontend to handle it. This allows for the administrator to
# disable the provider in the future and have it stop being rendered immediately, without any bad
# <iframe> tags lingering in the Markdown cache.
#
# Elements that receive the `js-render-iframe` class are skipped by AssetProxyFilter and
# ImageLazyLoadFilter, since proxying and lazy-loading are not applicable to iframe embeds.
module Banzai
  module Filter
    class IframeLinkFilter < PlayableLinkFilter
      prepend Concerns::PipelineTimingCheck
      include Concerns::ContextAccessors

      def call
        return doc unless Gitlab::CurrentSettings.iframe_rendering_enabled?

        return doc unless project&.allow_iframes_in_markdown_feature_flag_enabled? ||
          group&.allow_iframes_in_markdown_feature_flag_enabled?

        doc.xpath(XPATH).each do |el|
          match = ::Gitlab::Markdown::IframeProviders.match(el.attr('src'))
          next unless match

          el['data-iframe-canonical-src'] = el['src']
          el['data-iframe-provider-id'] = match.provider.id
          el['src'] = match.url
          el.replace(media_node(doc, el))
        end

        doc
      end

      private

      def media_type
        'img'
      end

      def extra_element_attrs(element)
        attrs = {
          'data-iframe-canonical-src' => element['data-iframe-canonical-src'],
          'data-iframe-provider-id' => element['data-iframe-provider-id'],
          class: 'js-render-iframe'
        }

        attrs[:height] = element[:height] if element[:height]
        attrs[:width] = element[:width] if element[:width]

        attrs
      end
    end
  end
end
