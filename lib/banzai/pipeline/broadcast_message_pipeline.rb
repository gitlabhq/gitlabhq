module Banzai
  module Pipeline
    class BroadcastMessagePipeline < DescriptionPipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::MarkdownFilter,
          Filter::SanitizationFilter,

          Filter::EmojiFilter,
          Filter::AutolinkFilter,
          Filter::ExternalLinkFilter
        ]
      end
    end
  end
end
