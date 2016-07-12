module Banzai
  module Pipeline
    class GfmPipeline < BasePipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::SyntaxHighlightFilter,
          Filter::SanitizationFilter,

          Filter::UploadLinkFilter,
          Filter::VideoLinkFilter,
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
          Filter::InlineDiffFilter
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
