require 'gitlab/markdown'

module Gitlab
  module Markdown
    class GfmPipeline < Pipeline
      def self.filters
        @filters ||= [
          Gitlab::Markdown::SyntaxHighlightFilter,
          Gitlab::Markdown::SanitizationFilter,

          Gitlab::Markdown::UploadLinkFilter,
          Gitlab::Markdown::EmojiFilter,
          Gitlab::Markdown::TableOfContentsFilter,
          Gitlab::Markdown::AutolinkFilter,
          Gitlab::Markdown::ExternalLinkFilter,

          Gitlab::Markdown::UserReferenceFilter,
          Gitlab::Markdown::IssueReferenceFilter,
          Gitlab::Markdown::ExternalIssueReferenceFilter,
          Gitlab::Markdown::MergeRequestReferenceFilter,
          Gitlab::Markdown::SnippetReferenceFilter,
          Gitlab::Markdown::CommitRangeReferenceFilter,
          Gitlab::Markdown::CommitReferenceFilter,
          Gitlab::Markdown::LabelReferenceFilter,

          Gitlab::Markdown::TaskListFilter
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
