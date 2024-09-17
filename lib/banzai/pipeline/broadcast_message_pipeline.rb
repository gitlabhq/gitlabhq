# frozen_string_literal: true

module Banzai
  module Pipeline
    class BroadcastMessagePipeline < DescriptionPipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::BlockquoteFenceLegacyFilter,
          Filter::MarkdownFilter,
          Filter::BroadcastMessageSanitizationFilter,
          Filter::SanitizeLinkFilter,
          Filter::EmojiFilter,
          Filter::ColorFilter,
          Filter::AutolinkFilter,
          Filter::ExternalLinkFilter
        ]
      end

      def self.transform_context(context)
        super(context).merge(
          no_sourcepos: true
        )
      end
    end
  end
end
