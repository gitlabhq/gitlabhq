# frozen_string_literal: true

# Converts `<iframe>` HTML tags (e.g. copy-pasted embed code from YouTube or Figma) into
# `<img>` tags so they survive sanitization and can be processed by IframeLinkFilter, the
# same as embeds using GitLab's `![]()` embed syntax.
#
# This filter runs *before* SanitizationFilter. Without it, `<iframe>`s would be stripped
# entirely by the sanitizer, as we don't really want to ever permit them in HTML output
# from (and cached by) the backend.
#
# The converted `<img>` tags carry through the `src`, `width`, and `height` attributes,
# are later picked up by IframeLinkFilter which applies URL transforms, checks the allowlist,
# and on match, adds the `js-render-iframe` class for frontend conversion into actual
# sandboxed iframes.
#
# If they don't match, they're left as harmless `<img>` tags.
module Banzai
  module Filter
    class IframeToImgFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath('iframe[src]').freeze

      def call
        return doc unless Gitlab::CurrentSettings.iframe_rendering_enabled?

        doc.xpath(XPATH).each do |iframe|
          iframe.replace(build_img(iframe))
        end

        doc
      end

      private

      def build_img(iframe)
        img = doc.document.create_element('img')
        img['src'] = iframe['src']
        img['width'] = iframe['width'] if iframe['width']
        img['height'] = iframe['height'] if iframe['height']
        img
      end
    end
  end
end
