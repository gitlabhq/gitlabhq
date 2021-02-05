# frozen_string_literal: true

module Banzai
  module Pipeline
    class PlainMarkdownPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::MarkdownPreEscapeFilter,
          Filter::MarkdownFilter,
          Filter::MarkdownPostEscapeFilter
        ]
      end
    end
  end
end
