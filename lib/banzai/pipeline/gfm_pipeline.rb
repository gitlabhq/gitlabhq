# frozen_string_literal: true

module Banzai
  module Pipeline
    class GfmPipeline < BasePipeline
      # These filters transform GitLab Flavored Markdown (GFM) to HTML.
      # The nodes and marks referenced in app/assets/javascripts/behaviors/markdown/editor_extensions.js
      # consequently transform that same HTML to GFM to be copied to the clipboard.
      # Every filter that generates HTML from GFM should have a node or mark in
      # app/assets/javascripts/behaviors/markdown/editor_extensions.js.
      # The GFM-to-HTML-to-GFM cycle is tested in spec/features/copy_as_gfm_spec.rb.
      def self.filters
        @filters ||= FilterArray[
          Filter::PlantumlFilter,
          # Must always be before the SanitizationFilter to prevent XSS attacks
          Filter::SpacedLinkFilter,
          Filter::SanitizationFilter,
          Filter::AssetProxyFilter,
          Filter::SyntaxHighlightFilter,
          Filter::MathFilter,
          Filter::ColorFilter,
          Filter::KrokiFilter,
          Filter::MermaidFilter,
          Filter::VideoLinkFilter,
          Filter::AudioLinkFilter,
          Filter::ImageLazyLoadFilter,
          Filter::ImageLinkFilter,
          *metrics_filters,
          Filter::TableOfContentsFilter,
          Filter::TableOfContentsTagFilter,
          Filter::AutolinkFilter,
          Filter::ExternalLinkFilter,
          Filter::SuggestionFilter,
          Filter::FootnoteFilter,
          *reference_filters,
          Filter::EmojiFilter,
          Filter::CustomEmojiFilter,
          Filter::TaskListFilter,
          Filter::InlineDiffFilter,
          Filter::SetDirectionFilter
        ]
      end

      def self.metrics_filters
        [
          Filter::InlineMetricsFilter,
          Filter::InlineGrafanaMetricsFilter,
          Filter::InlineClusterMetricsFilter
        ]
      end

      def self.reference_filters
        [
          Filter::References::UserReferenceFilter,
          Filter::References::ProjectReferenceFilter,
          Filter::References::DesignReferenceFilter,
          Filter::References::IssueReferenceFilter,
          Filter::References::ExternalIssueReferenceFilter,
          Filter::References::MergeRequestReferenceFilter,
          Filter::References::SnippetReferenceFilter,
          Filter::References::CommitRangeReferenceFilter,
          Filter::References::CommitReferenceFilter,
          Filter::References::LabelReferenceFilter,
          Filter::References::MilestoneReferenceFilter,
          Filter::References::AlertReferenceFilter,
          Filter::References::FeatureFlagReferenceFilter
        ]
      end

      def self.transform_context(context)
        context[:only_path] = true unless context.key?(:only_path)

        Filter::AssetProxyFilter.transform_context(context)
      end
    end
  end
end

Banzai::Pipeline::GfmPipeline.prepend_mod_with('Banzai::Pipeline::GfmPipeline')
