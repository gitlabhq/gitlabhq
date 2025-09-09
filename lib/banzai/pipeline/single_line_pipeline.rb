# frozen_string_literal: true

module Banzai
  module Pipeline
    class SingleLinePipeline < BasePipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::HtmlEntityFilter,
          Filter::MinimumMarkdownSanitizationFilter,
          Filter::SanitizeLinkFilter,
          Filter::AssetProxyFilter,
          Filter::EmojiFilter,
          Filter::CustomEmojiFilter,
          Filter::AutolinkFilter,
          Filter::ExternalLinkFilter,
          *reference_filters
        ]
      end

      def self.reference_filters
        [
          Filter::References::UserReferenceFilter,
          Filter::References::IssueReferenceFilter,
          Filter::References::WorkItemReferenceFilter,
          Filter::References::ExternalIssueReferenceFilter,
          Filter::References::MergeRequestReferenceFilter,
          Filter::References::SnippetReferenceFilter,
          Filter::References::CommitRangeReferenceFilter,
          Filter::References::CommitReferenceFilter,
          Filter::References::AlertReferenceFilter,
          Filter::References::FeatureFlagReferenceFilter,
          Filter::References::WikiPageReferenceFilter
        ]
      end

      def self.transform_context(context)
        context = Filter::AssetProxyFilter.transform_context(context)
        context[:only_path] = true unless context.key?(:only_path)

        context
      end
    end
  end
end

Banzai::Pipeline::SingleLinePipeline.prepend_mod_with('Banzai::Pipeline::SingleLinePipeline')
