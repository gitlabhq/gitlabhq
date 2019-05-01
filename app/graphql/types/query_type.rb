# frozen_string_literal: true

module Types
  class QueryType < ::Types::BaseObject
    graphql_name 'Query'

    field :project, Types::ProjectType,
          null: true,
          resolver: Resolvers::ProjectResolver,
          description: "Find a project"

    field :group, Types::GroupType,
          null: true,
          resolver: Resolvers::GroupResolver,
          description: "Find a group"

    field :metadata, Types::MetadataType,
          null: true,
          resolver: Resolvers::MetadataResolver,
          description: 'Metadata about GitLab' do |*args|

      authorize :read_instance_metadata
    end

    field :echo, GraphQL::STRING_TYPE, null: false, function: Functions::Echo.new
  end
end
