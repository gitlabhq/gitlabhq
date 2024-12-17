# frozen_string_literal: true

module Banzai
  module Pipeline
    class PlainMarkdownPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::IncludeFilter,
          Filter::MarkdownPreEscapeLegacyFilter,
          Filter::DollarMathPreLegacyFilter,
          Filter::BlockquoteFenceLegacyFilter,
          Filter::MarkdownFilter,
          Filter::ConvertTextToDocFilter,
          Filter::DollarMathPostLegacyFilter,
          Filter::MarkdownPostEscapeLegacyFilter
        ]
      end
    end
  end
end
