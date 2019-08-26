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
          Filter::UserReferenceFilter,
          Filter::IssueReferenceFilter,
          Filter::ExternalIssueReferenceFilter,
          Filter::MergeRequestReferenceFilter,
          Filter::SnippetReferenceFilter,
          Filter::CommitRangeReferenceFilter,
          Filter::CommitReferenceFilter
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
