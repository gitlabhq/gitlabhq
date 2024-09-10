# frozen_string_literal: true

module Banzai
  module Pipeline
    class EmojiPipeline < BasePipeline
      # These filters will only perform sanitization of the content, preventing
      # XSS, and replace emoji.
      def self.filters
        @filters ||= FilterArray[
          Filter::HtmlEntityFilter,
          Filter::SanitizationFilter,
          Filter::SanitizeLinkFilter,
          Filter::EmojiFilter
        ]
      end
    end
  end
end
