# frozen_string_literal: true

# Determines if an `img` tag references media to be embedded in an `iframe`. The administrator
# needs to explicitly allow the domain and consider it trusted. The `js-render-iframe` class
# will get added to allow the frontend to convert into an `iframe`.
#
# Before checking the allowlist, URL transforms are applied (e.g. YouTube watch URLs are
# rewritten to embed URLs). The original user-provided URL is preserved in
# `data-iframe-canonical-src` for the rich-text editor.
#
# Even though the `iframe` src will have been allowed by the administrator, don't insert
# the `iframe` tag here on the backend - allow the frontend to handle it. This allows for
# the administrator to remove the domain in the future if it becomes untrusted for some reason.
# The markdown cache will not need to be cleared as long as the `iframe` is added on the frontend.
#
# Elements that receive the `js-render-iframe` class are skipped by AssetProxyFilter and
# ImageLazyLoadFilter, since proxying and lazy-loading are not applicable to iframe embeds.
module Banzai
  module Filter
    class IframeLinkFilter < PlayableLinkFilter
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      def call
        return doc unless Gitlab::CurrentSettings.iframe_rendering_enabled?

        return doc unless context[:project]&.allow_iframes_in_markdown_feature_flag_enabled? ||
          context[:group]&.allow_iframes_in_markdown_feature_flag_enabled?

        transform_urls!

        super
      end

      private

      def media_type
        'img'
      end

      def safe_media_ext
        Gitlab::CurrentSettings.iframe_rendering_allowlist.map do |domain|
          Addressable::URI.parse("https://#{domain}")
        end
      end
      strong_memoize_attr :safe_media_ext

      # Check the transformed src (not data-canonical-src as the base class does),
      # because the allowlist must match against the final embed domain
      # (e.g. embed.figma.com), not the original user-provided domain (www.figma.com).
      override :has_allowed_media?
      def has_allowed_media?(element)
        src = element.attr('src')
        return unless src.present?

        uri = Addressable::URI.parse(src)
        safe_media_ext.any? { |allowed_uri| allowed_uri.origin == uri.origin }
      end

      def transform_urls!
        doc.xpath(XPATH).each do |el|
          src = el.attr('src')
          next unless src.present?

          transformed = ::Gitlab::Markdown::IframeUrlTransforms.transform(src)
          next if transformed == src

          el['data-iframe-canonical-src'] = src
          el['src'] = transformed
        end
      end

      def extra_element_attrs(element)
        attrs = {}

        attrs[:height] = element[:height] if element[:height]
        attrs[:width] = element[:width] if element[:width]
        if element['data-iframe-canonical-src']
          attrs['data-iframe-canonical-src'] = element['data-iframe-canonical-src']
        end

        attrs[:class] = 'js-render-iframe'

        attrs
      end
    end
  end
end
