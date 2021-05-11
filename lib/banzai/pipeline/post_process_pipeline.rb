# frozen_string_literal: true

module Banzai
  module Pipeline
    class PostProcessPipeline < BasePipeline
      def self.filters
        @filters ||= FilterArray[
          *internal_link_filters,
          Filter::AbsoluteLinkFilter,
          Filter::BroadcastMessagePlaceholdersFilter
        ]
      end

      def self.internal_link_filters
        [
          Filter::ReferenceRedactorFilter,
          Filter::InlineMetricsRedactorFilter,
          # UploadLinkFilter must come before RepositoryLinkFilter to
          # prevent unnecessary Gitaly calls from being made.
          Filter::UploadLinkFilter,
          Filter::RepositoryLinkFilter,
          Filter::IssuableStateFilter,
          Filter::SuggestionFilter
        ]
      end

      def self.transform_context(context)
        context.merge(
          post_process: true
        )
      end
    end
  end
end

Banzai::Pipeline::PostProcessPipeline.prepend_mod_with('Banzai::Pipeline::PostProcessPipeline')
