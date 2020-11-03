# frozen_string_literal: true

module Resolvers
  class ProjectPipelinesResolver < BaseResolver
    include LooksAhead
    include ResolvesPipelines

    alias_method :project, :object

    def resolve_with_lookahead(**args)
      apply_lookahead(resolve_pipelines(project, args))
    end

    private

    def preloads
      {
        jobs: [:statuses],
        upstream: [:triggered_by_pipeline],
        downstream: [:triggered_pipelines]
      }
    end
  end
end
