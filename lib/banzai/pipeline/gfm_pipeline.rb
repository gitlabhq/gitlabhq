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
          Filter::MermaidFilter,
          Filter::VideoLinkFilter,
          Filter::ImageLazyLoadFilter,
          Filter::ImageLinkFilter,
          Filter::InlineMetricsFilter,
          Filter::TableOfContentsFilter,
          Filter::AutolinkFilter,
          Filter::ExternalLinkFilter,
          Filter::SuggestionFilter,
          Filter::FootnoteFilter,

          *reference_filters,

          Filter::EmojiFilter,
          Filter::TaskListFilter,
          Filter::InlineDiffFilter,

          Filter::SetDirectionFilter
        ]
      end

      def self.reference_filters
        [
          Filter::UserReferenceFilter,
          Filter::ProjectReferenceFilter,
          Filter::IssueReferenceFilter,
          Filter::ExternalIssueReferenceFilter,
          Filter::MergeRequestReferenceFilter,
          Filter::SnippetReferenceFilter,
          Filter::CommitRangeReferenceFilter,
          Filter::CommitReferenceFilter,
          Filter::LabelReferenceFilter,
          Filter::MilestoneReferenceFilter
        ]
      end

      def self.transform_context(context)
        context[:only_path] = true unless context.key?(:only_path)

        Filter::AssetProxyFilter.transform_context(context)
      end
    end
  end
end
