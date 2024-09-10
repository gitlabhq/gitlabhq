# frozen_string_literal: true

module Banzai
  module Pipeline
    class AsciiDocPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::AsciiDocSanitizationFilter,
          Filter::SanitizeLinkFilter,
          Filter::CodeLanguageFilter,
          Filter::GollumTagsFilter,
          Filter::WikiLinkGollumFilter,
          Filter::AssetProxyFilter,
          Filter::ExternalLinkFilter,
          Filter::PlantumlFilter,
          Filter::ColorFilter,
          Filter::ImageLazyLoadFilter,
          Filter::ImageLinkFilter,
          Filter::WikiLinkFilter,
          Filter::SyntaxHighlightFilter, # this filter should remain next to last
          Filter::AsciiDocPostProcessingFilter
        ]
      end

      def self.transform_context(context)
        Filter::AssetProxyFilter.transform_context(context)
      end
    end
  end
end
