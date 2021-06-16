# frozen_string_literal: true

module Banzai
  module Pipeline
    class MarkupPipeline < BasePipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::SanitizationFilter,
          Filter::AssetProxyFilter,
          Filter::ExternalLinkFilter,
          Filter::PlantumlFilter,
          Filter::SyntaxHighlightFilter,
          Filter::KrokiFilter
        ]
      end

      def self.transform_context(context)
        Filter::AssetProxyFilter.transform_context(context)
      end
    end
  end
end
