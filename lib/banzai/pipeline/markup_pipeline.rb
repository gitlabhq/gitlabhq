# frozen_string_literal: true

module Banzai
  module Pipeline
    class MarkupPipeline < BasePipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::SanitizationFilter,
          Filter::ExternalLinkFilter,
          Filter::PlantumlFilter
        ]
      end
    end
  end
end
