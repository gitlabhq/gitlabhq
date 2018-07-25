module Banzai
  module Pipeline
    class SingleLinePipeline < GfmPipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::HtmlEntityFilter,
          Filter::SanitizationFilter,

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
    end
  end
end
