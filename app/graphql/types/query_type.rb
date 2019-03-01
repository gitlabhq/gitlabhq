# frozen_string_literal: true

module Types
  class QueryType < BaseObject
    graphql_name 'Query'

    field :project, Types::ProjectType,
          null: true,
          resolver: Resolvers::ProjectResolver,
          description: "Find a project",
          authorize: :read_project

    field :echo, GraphQL::STRING_TYPE, null: false, function: Functions::Echo.new
  end
end
