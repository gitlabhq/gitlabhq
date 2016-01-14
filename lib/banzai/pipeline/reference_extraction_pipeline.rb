module Banzai
  module Pipeline
    class ReferenceExtractionPipeline < BasePipeline
      def self.filters
        [
          Filter::ReferenceGathererFilter
        ]
      end
    end
  end
end
