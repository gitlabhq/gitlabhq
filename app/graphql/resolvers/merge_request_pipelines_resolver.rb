# frozen_string_literal: true

module Resolvers
  class MergeRequestPipelinesResolver < BaseResolver
    include ::ResolvesPipelines

    alias_method :merge_request, :object

    def resolve(**args)
      resolve_pipelines(project, args)
        .merge(merge_request.all_pipelines)
    end

    def project
      merge_request.source_project
    end
  end
end
