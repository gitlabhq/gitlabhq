# frozen_string_literal: true

GraphQL::ObjectType.accepts_definitions(authorize: GraphQL::Define.assign_metadata_key(:authorize))
GraphQL::Field.accepts_definitions(authorize: GraphQL::Define.assign_metadata_key(:authorize))

GraphQL::Schema::Object.accepts_definition(:authorize)
GraphQL::Schema::Field.accepts_definition(:authorize)

GitlabSchema.middleware << GraphQL::Schema::TimeoutMiddleware.new(max_seconds: ENV.fetch('GITLAB_RAILS_GRAPHQL_TIMEOUT', 30).to_i) do |timeout_error, query|
  Gitlab::GraphqlLogger.error(message: timeout_error.to_s, query: query.query_string, query_variables: query.provided_variables)
end
