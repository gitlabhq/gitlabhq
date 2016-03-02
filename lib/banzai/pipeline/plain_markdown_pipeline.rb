module Banzai
  module Pipeline
    class PlainMarkdownPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::MarkdownFilter
        ]
      end
    end
  end
end
