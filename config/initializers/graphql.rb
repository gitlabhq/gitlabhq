# frozen_string_literal: true

GraphQL::ObjectType.accepts_definitions(authorize: GraphQL::Define.assign_metadata_key(:authorize))
GraphQL::Field.accepts_definitions(authorize: GraphQL::Define.assign_metadata_key(:authorize))

GraphQL::Schema::Object.accepts_definition(:authorize)
GraphQL::Schema::Field.accepts_definition(:authorize)

Gitlab::Application.config.after_initialize do
  GitlabSchema.middleware << GraphQL::Schema::TimeoutMiddleware.new(max_seconds: Gitlab.config.gitlab.graphql_timeout) do |timeout_error, query|
    Gitlab::GraphqlLogger.error(message: timeout_error.to_s, query: query.query_string, query_variables: query.provided_variables)
  end
end
