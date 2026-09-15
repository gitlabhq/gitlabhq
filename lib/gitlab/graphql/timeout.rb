# frozen_string_literal: true

module Gitlab
  module Graphql
    class Timeout < GraphQL::Schema::Timeout
      def handle_timeout(error, query)
        Gitlab::GraphqlLogger.error(
          message: error.message,
          query: LogSanitizer.query_string(query),
          query_variables: LogSanitizer.variables(query.provided_variables, query.operation_name)
        )
      end
    end
  end
end
