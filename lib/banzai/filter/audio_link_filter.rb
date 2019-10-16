# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/audio.js
module Banzai
  module Filter
    class AudioLinkFilter < PlayableLinkFilter
      private

      def media_type
        "audio"
      end

      def safe_media_ext
        Gitlab::FileTypeDetection::SAFE_AUDIO_EXT
      end
    end
  end
end
