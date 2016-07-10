module Banzai
  module Pipeline
    class AutolinkPipeline < BasePipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::AutolinkFilter,
          Filter::ExternalLinkFilter
        ]
      end
    end
  end
end
