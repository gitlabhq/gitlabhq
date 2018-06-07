module Types
  class QueryType < BaseObject
    graphql_name 'Query'

    field :project, Types::ProjectType,
          null: true,
          resolver: Resolvers::ProjectResolver,
          description: "Find a project" do
      authorize :read_project
    end

    field :merge_request, Types::MergeRequestType,
          null: true,
          resolver: Resolvers::MergeRequestResolver,
          description: "Find a merge request" do
      authorize :read_merge_request
    end

    field :echo, GraphQL::STRING_TYPE, null: false, function: Functions::Echo.new
  end
end
