module Banzai
  module Pipeline
    class PlainMarkdownPipeline < BasePipeline
      def self.filters
        [
          Filter::MarkdownFilter
        ]
      end
    end
  end
end
