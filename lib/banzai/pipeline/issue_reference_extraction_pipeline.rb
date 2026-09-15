# frozen_string_literal: true

module Banzai
  module Pipeline
    # Reference filters cannot change what earlier filters matched, so issue
    # extraction can drop everything after the issue filters - including the
    # commit filters, which resolve any 7-64 character hex word through Gitaly.
    class IssueReferenceExtractionPipeline < FullPipeline
      LAST_REQUIRED_REFERENCE_FILTER = Filter::References::ExternalIssueReferenceFilter

      def self.filters
        @filters ||= FilterArray.new(super - unused_reference_filters)
      end

      def self.unused_reference_filters
        reference_filters = GfmPipeline.reference_filters

        reference_filters.drop(reference_filters.index(LAST_REQUIRED_REFERENCE_FILTER) + 1)
      end
    end
  end
end
