# frozen_string_literal: true

module Banzai
  module Pipeline
    class UserBioPipeline < BasePipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::MarkdownFilter,
          Filter::UserBioSanitizationFilter,
          Filter::TrimWhitespaceFilter,
          Filter::EmojiFilter
        ]
      end

      def self.transform_context(context)
        super.merge(
          no_sourcepos: true
        )
      end
    end
  end
end
