# frozen_string_literal: true

module Banzai
  module Pipeline
    class PostProcessPipeline < BasePipeline
      def self.filters
        @filters ||= FilterArray[
          *internal_link_filters,
          Filter::AbsoluteLinkFilter
        ]
      end

      def self.internal_link_filters
        [
          Filter::RedactorFilter,
          Filter::InlineMetricsRedactorFilter,
          Filter::RelativeLinkFilter,
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
