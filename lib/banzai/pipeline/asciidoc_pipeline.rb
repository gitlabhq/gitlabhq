module Banzai
  module Pipeline
    class AsciidocPipeline < BasePipeline
      def self.filters
        [
          Filter::RelativeLinkFilter
        ]
      end
    end
  end
end
