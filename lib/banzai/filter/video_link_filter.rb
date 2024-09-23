# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/video.js
module Banzai
  module Filter
    class VideoLinkFilter < PlayableLinkFilter
      private

      def media_type
        'video'
      end

      def safe_media_ext
        Gitlab::FileTypeDetection::SAFE_VIDEO_EXT
      end

      def extra_element_attrs(element)
        attrs = { preload: 'metadata' }

        attrs[:height] = element[:height] if element[:height]
        attrs[:width] = element[:width] if element[:width]

        attrs
      end
    end
  end
end
