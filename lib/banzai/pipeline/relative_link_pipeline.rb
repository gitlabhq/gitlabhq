module Banzai
  module Pipeline
    class RelativeLinkPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::RelativeLinkFilter
        ]
      end
    end
  end
end
