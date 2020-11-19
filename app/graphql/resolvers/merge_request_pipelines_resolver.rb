# frozen_string_literal: true
# rubocop: disable Graphql/ResolverType

module Resolvers
  class MergeRequestPipelinesResolver < BaseResolver
    # The GraphQL type here gets defined in this include
    include ::ResolvesPipelines

    alias_method :merge_request, :object

    def resolve(**args)
      return unless project

      resolve_pipelines(project, args)
        .merge(merge_request.all_pipelines)
    end

    def project
      merge_request.source_project
    end
  end
end
# rubocop: enable Graphql/ResolverType
