# frozen_string_literal: true

# Determines if an `img` tag references media to be embedded in an `iframe`. The administrator
# needs to explicitly allow the domain and consider it trusted. The `js-render-iframe` class
# will get added to allow the frontend to convert into an `iframe`
#
# Even though the `iframe` src will have been allowed by the administrator, don't insert
# the `iframe` tag here on the backend - allow the frontend to handle it. This allows for
# the administrator to remove the domain in the future if it becomes untrusted for some reason.
# The markdown cache will not need to cleared as long as the `iframe` is added on the frontend.
module Banzai
  module Filter
    class IframeLinkFilter < PlayableLinkFilter
      extend ::Gitlab::Utils::Override

      private

      def media_type
        'img'
      end

      def safe_media_ext
        # TODO: will change to use the administrator defined allow list
        #       Gitlab::CurrentSettings.iframe_src_allowlist
        ['www.youtube.com/embed']
      end

      override :has_allowed_media?
      def has_allowed_media?(element)
        return unless context[:project]&.allow_iframes_in_markdown_feature_flag_enabled? ||
          context[:group]&.allow_iframes_in_markdown_feature_flag_enabled?

        src = element.attr('data-canonical-src').presence || element.attr('src')

        return unless src.present?

        src.start_with?('https://') && safe_media_ext.any? { |domain| src.start_with?("https://#{domain}") }
      end

      def extra_element_attrs(element)
        attrs = {}

        attrs[:height] = element[:height] if element[:height]
        attrs[:width] = element[:width] if element[:width]
        attrs[:class] = 'js-render-iframe'

        attrs
      end
    end
  end
end
