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

      def self.transform_context(context)
        context.merge(disable_raw_html: true)
      end
    end
  end
end
