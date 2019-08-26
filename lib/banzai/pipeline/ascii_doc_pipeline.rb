# frozen_string_literal: true

module Banzai
  module Pipeline
    class AsciiDocPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::SanitizationFilter,
          Filter::AssetProxyFilter,
          Filter::ExternalLinkFilter,
          Filter::PlantumlFilter,
          Filter::AsciiDocPostProcessingFilter
        ]
      end

      def self.transform_context(context)
        Filter::AssetProxyFilter.transform_context(context)
      end
    end
  end
end
