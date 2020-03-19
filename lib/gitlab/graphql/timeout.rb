# frozen_string_literal: true

module Gitlab
  module Graphql
    class Timeout < GraphQL::Schema::Timeout
      def handle_timeout(error, query)
        Gitlab::GraphqlLogger.error(message: error.message, query: query.query_string, query_variables: query.provided_variables)
      end
    end
  end
end
