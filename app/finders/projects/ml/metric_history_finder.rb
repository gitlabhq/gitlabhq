# frozen_string_literal: true

module Projects
  module Ml
    class MetricHistoryFinder
      def initialize(candidate, metric_key)
        @candidate = candidate
        @metric_key = metric_key
      end

      def execute
        ::Ml::CandidateMetric.for_history(@candidate.id, @metric_key)
      end
    end
  end
end
