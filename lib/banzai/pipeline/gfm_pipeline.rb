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
          Filter::CodeLanguageFilter,
          Filter::JsonTableFilter, # process before sanitization
          Filter::PlantumlFilter,
          # Must always be before the SanitizationFilter/SanitizeLinkFilter to prevent XSS attacks
          Filter::SpacedLinkFilter,
          Filter::SanitizationFilter,
          Filter::SanitizeLinkFilter,
          Filter::EscapedCharFilter,
          Filter::KrokiFilter,
          Filter::GollumTagsFilter,
          Filter::WikiLinkGollumFilter,
          Filter::AssetProxyFilter,
          Filter::MathFilter,
          Filter::ColorFilter,
          Filter::MermaidFilter,
          Filter::AttributesFilter,
          Filter::VideoLinkFilter,
          Filter::AudioLinkFilter,
          Filter::TableOfContentsLegacyFilter,
          Filter::TableOfContentsTagLegacyFilter,
          Filter::TableOfContentsTagFilter,
          Filter::AutolinkFilter,
          Filter::SuggestionFilter,
          Filter::FootnoteFilter,
          Filter::InlineDiffFilter,
          *reference_filters,
          Filter::ImageLazyLoadFilter, # keep after reference filters
          Filter::ImageLinkFilter, # keep after reference filters
          Filter::ExternalLinkFilter, # keep after ImageLinkFilter
          Filter::EmojiFilter,
          Filter::CustomEmojiFilter,
          Filter::TaskListFilter,
          Filter::SetDirectionFilter,
          Filter::SyntaxHighlightFilter # this filter should remain at the end
        ]
      end

      def self.reference_filters
        [
          Filter::References::UserReferenceFilter,
          Filter::References::ProjectReferenceFilter,
          Filter::References::DesignReferenceFilter,
          Filter::References::IssueReferenceFilter,
          Filter::References::WorkItemReferenceFilter,
          Filter::References::ExternalIssueReferenceFilter,
          Filter::References::MergeRequestReferenceFilter,
          Filter::References::SnippetReferenceFilter,
          Filter::References::CommitRangeReferenceFilter,
          Filter::References::LabelReferenceFilter,
          Filter::References::MilestoneReferenceFilter,
          Filter::References::AlertReferenceFilter,
          Filter::References::FeatureFlagReferenceFilter,
          Filter::References::CommitReferenceFilter
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
