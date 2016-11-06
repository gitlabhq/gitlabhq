module Banzai
  module Pipeline
    class RelativeLinkPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::RelativeLinkFilter,
          Filter::RichReferenceFilter
        ]
      end
    end
  end
end
