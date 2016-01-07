module Banzai
  module Pipeline
    class PostProcessPipeline < BasePipeline
      def self.filters
        [
          Filter::RelativeLinkFilter,
          Filter::RedactorFilter
        ]
      end

      def self.transform_context(context)
        context.merge(
          post_process: true
        )
      end
    end
  end
end
