# frozen_string_literal: true

module Resolvers
  module Ci
    class PipelineStagesResolver < BaseResolver
      include LooksAhead

      alias_method :pipeline, :object

      def resolve_with_lookahead
        apply_lookahead(pipeline.stages)
      end

      def preloads
        {
          statuses: [:needs]
        }
      end
    end
  end
end
