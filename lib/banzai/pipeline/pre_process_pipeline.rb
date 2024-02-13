# frozen_string_literal: true

module Banzai
  module Pipeline
    class PreProcessPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::NormalizeSourceFilter,
          Filter::TruncateSourceFilter,
          Filter::FrontMatterFilter,
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
