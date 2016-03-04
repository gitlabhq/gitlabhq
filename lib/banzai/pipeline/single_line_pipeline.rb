module Banzai
  module Pipeline
    class SingleLinePipeline < GfmPipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::SanitizationFilter,

          Filter::EmojiFilter,
          Filter::AutolinkFilter,
          Filter::ExternalLinkFilter,

          Filter::UserReferenceFilter,
          Filter::IssueReferenceFilter,
          Filter::ExternalIssueReferenceFilter,
          Filter::MergeRequestReferenceFilter,
          Filter::SnippetReferenceFilter,
          Filter::CommitRangeReferenceFilter,
          Filter::CommitReferenceFilter,
        ]
      end
    end
  end
end
