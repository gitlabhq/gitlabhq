# frozen_string_literal: true

module Banzai
  module Pipeline
    class PlainMarkdownPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::IncludeFilter,
          Filter::MarkdownFilter,
          Filter::ConvertTextToDocFilter,
        ]
      end
    end
  end
end
