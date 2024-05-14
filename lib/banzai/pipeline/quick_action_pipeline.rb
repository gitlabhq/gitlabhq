# frozen_string_literal: true

module Banzai
  module Pipeline
    # Pipeline for detecting possible paragraphs with quick actions,
    # leveraging the markdown processor
    class QuickActionPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::NormalizeSourceFilter,
          Filter::TruncateSourceFilter,
          Filter::FrontMatterFilter,
          Filter::BlockquoteFenceLegacyFilter,
          Filter::MarkdownFilter,
          Filter::QuickActionFilter
        ]
      end
    end
  end
end
