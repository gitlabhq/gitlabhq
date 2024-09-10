# frozen_string_literal: true

module Banzai
  module Pipeline
    class MarkupPipeline < BasePipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::SanitizationFilter,
          Filter::SanitizeLinkFilter,
          Filter::CodeLanguageFilter,
          Filter::AssetProxyFilter,
          Filter::ExternalLinkFilter,
          Filter::PlantumlFilter,
          Filter::KrokiFilter,
          Filter::SyntaxHighlightFilter # this filter should remain at the end
        ]
      end

      def self.transform_context(context)
        Filter::AssetProxyFilter.transform_context(context)
      end
    end
  end
end
