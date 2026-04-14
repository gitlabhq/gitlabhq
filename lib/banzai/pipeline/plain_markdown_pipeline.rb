# frozen_string_literal: true

module Banzai
  module Pipeline
    class PlainMarkdownPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::IncludeFilter,
          Filter::MarkdownFilter,
          Filter::ParseHtmlFilter
        ]
      end
    end
  end
end
