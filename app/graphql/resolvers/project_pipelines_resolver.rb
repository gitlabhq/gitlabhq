# frozen_string_literal: true

module Resolvers
  class ProjectPipelinesResolver < BaseResolver
    include ResolvesPipelines

    alias_method :project, :object

    def resolve(**args)
      resolve_pipelines(project, args)
    end
  end
end
