# frozen_string_literal: true

module Banzai
  module Pipeline
    class SingleLinePipeline < GfmPipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::HtmlEntityFilter,
          Filter::SanitizationFilter,
          Filter::AssetProxyFilter,
          Filter::EmojiFilter,
          Filter::AutolinkFilter,
          Filter::ExternalLinkFilter,
          *reference_filters
        ]
      end

      def self.reference_filters
        [
          Filter::References::UserReferenceFilter,
          Filter::References::IssueReferenceFilter,
          Filter::References::ExternalIssueReferenceFilter,
          Filter::References::MergeRequestReferenceFilter,
          Filter::References::SnippetReferenceFilter,
          Filter::References::CommitRangeReferenceFilter,
          Filter::References::CommitReferenceFilter,
          Filter::References::AlertReferenceFilter,
          Filter::References::FeatureFlagReferenceFilter
        ]
      end

      def self.transform_context(context)
        context = Filter::AssetProxyFilter.transform_context(context)

        super(context).merge(
          no_sourcepos: true
        )
      end
    end
  end
end

Banzai::Pipeline::SingleLinePipeline.prepend_mod_with('Banzai::Pipeline::SingleLinePipeline')
