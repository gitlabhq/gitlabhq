module Banzai
  module Pipeline
    class GfmPipeline < BasePipeline
      # These filters convert GitLab Flavored Markdown (GFM) to HTML.
      # The handlers defined in app/assets/javascripts/behaviors/markdown/copy_as_gfm.js
      # consequently convert that same HTML to GFM to be copied to the clipboard.
      # Every filter that generates HTML from GFM should have a handler in
      # app/assets/javascripts/behaviors/markdown/copy_as_gfm.js, in reverse order.
      # The GFM-to-HTML-to-GFM cycle is tested in spec/features/copy_as_gfm_spec.rb.
      def self.filters
        @filters ||= FilterArray[
          Filter::PlantumlFilter,
          Filter::SanitizationFilter,
          Filter::SyntaxHighlightFilter,

          Filter::MathFilter,
          Filter::ColorFilter,
          Filter::MermaidFilter,
          Filter::VideoLinkFilter,
          Filter::ImageLazyLoadFilter,
          Filter::ImageLinkFilter,
          Filter::EmojiFilter,
          Filter::TableOfContentsFilter,
          Filter::AutolinkFilter,
          Filter::ExternalLinkFilter,

          Filter::UserReferenceFilter,
          Filter::IssueReferenceFilter,
          Filter::ExternalIssueReferenceFilter,
          Filter::MergeRequestReferenceFilter,
          Filter::SnippetReferenceFilter,
          Filter::CommitRangeReferenceFilter,
          Filter::CommitReferenceFilter,
          Filter::LabelReferenceFilter,
          Filter::MilestoneReferenceFilter,

          Filter::TaskListFilter,
          Filter::InlineDiffFilter,

          Filter::SetDirectionFilter
        ]
      end

      def self.transform_context(context)
        context.merge(
          only_path: true,

          # EmojiFilter
          asset_host: Gitlab::Application.config.asset_host,
          asset_root: Gitlab.config.gitlab.base_url
        )
      end
    end
  end
end
