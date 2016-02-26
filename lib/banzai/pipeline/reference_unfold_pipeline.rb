module Banzai
  module Pipeline
    class ReferenceUnfoldPipeline < BasePipeline
      def self.filters
        [Filter::ReferenceUnfoldFilter]
      end
    end
  end
end
