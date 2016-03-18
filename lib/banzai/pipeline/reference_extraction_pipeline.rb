module Banzai
  module Pipeline
    class ReferenceExtractionPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::ReferenceGathererFilter
        ]
      end
    end
  end
end
