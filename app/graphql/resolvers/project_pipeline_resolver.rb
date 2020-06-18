# frozen_string_literal: true

module Resolvers
  class ProjectPipelineResolver < BaseResolver
    alias_method :project, :object

    argument :iid, GraphQL::ID_TYPE,
             required: true,
             description: 'IID of the Pipeline, e.g., "1"'

    def resolve(iid:)
      BatchLoader::GraphQL.for(iid).batch(key: project) do |iids, loader, args|
        args[:key].ci_pipelines.for_iid(iids).each { |pl| loader.call(pl.iid.to_s, pl) }
      end
    end
  end
end
