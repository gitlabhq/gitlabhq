# frozen_string_literal: true
# rubocop: disable Graphql/ResolverType

module Resolvers
  class CommitPipelinesResolver < BaseResolver
    # The GraphQL type here gets defined in this include
    include ::ResolvesPipelines

    alias_method :commit, :object

    def resolve(**args)
      resolve_pipelines(commit.project, args.merge!({ sha: commit.sha }))
    end
  end
end
# rubocop: enable Graphql/ResolverType
