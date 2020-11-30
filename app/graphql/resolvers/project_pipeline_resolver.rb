# frozen_string_literal: true

module Resolvers
  class ProjectPipelineResolver < BaseResolver
    type ::Types::Ci::PipelineType, null: true

    alias_method :project, :object

    argument :iid, GraphQL::ID_TYPE,
             required: true,
             description: 'IID of the Pipeline, e.g., "1"'

    def resolve(iid:)
      BatchLoader::GraphQL.for(iid).batch(key: project) do |iids, loader, args|
        finder = ::Ci::PipelinesFinder.new(project, context[:current_user], iids: iids)

        finder.execute.each { |pipeline| loader.call(pipeline.iid.to_s, pipeline) }
      end
    end
  end
end
