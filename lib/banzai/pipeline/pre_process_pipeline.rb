module Banzai
  module Pipeline
    class PreProcessPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::YamlFrontMatterFilter
        ]
      end

      def self.transform_context(context)
        context.merge(
          pre_process: true
        )
      end
    end
  end
end
