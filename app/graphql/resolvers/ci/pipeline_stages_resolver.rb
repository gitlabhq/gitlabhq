# frozen_string_literal: true

module Resolvers
  module Ci
    class PipelineStagesResolver < BaseResolver
      include LooksAhead

      type Types::Ci::StageType.connection_type, null: true
      extras [:lookahead]

      alias_method :pipeline, :object

      def resolve_with_lookahead
        apply_lookahead(pipeline.stages)
      end

      def preloads
        {
          jobs: { latest_statuses: [:needs] }
        }
      end
    end
  end
end
