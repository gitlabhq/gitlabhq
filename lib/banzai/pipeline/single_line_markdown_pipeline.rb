# frozen_string_literal: true

module Banzai
  module Pipeline
    # Does the same transformation as SingleLinePipeline, but runs
    # it through the MarkdownFilter first
    class SingleLineMarkdownPipeline < SingleLinePipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::MarkdownFilter,
          Filter::ConvertTextToDocFilter,
          Filter::MinimumMarkdownSanitizationFilter,
          Filter::SanitizeLinkFilter,
          Filter::AssetProxyFilter,
          Filter::EmojiFilter,
          Filter::CustomEmojiFilter,
          Filter::ExternalLinkFilter,
          *reference_filters
        ]
      end

      # UserReferenceFilter is intentionally excluded to prevent generating
      # a notification. This pipeline is mostly for titles.
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
        super.merge(minimum_markdown: true)
      end
    end
  end
end

Banzai::Pipeline::SingleLinePipeline.prepend_mod_with('Banzai::Pipeline::SingleLineMarkdownPipeline')
