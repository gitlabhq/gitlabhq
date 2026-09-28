# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      # rubocop:disable GraphQL/GraphqlName, Graphql/AuthorizeTypes -- Field subclass, not a GraphQL type.
      class AggregationField < Types::BaseField
        extend ::Gitlab::Utils::Override

        private

        override :connection_max_page_size
        def connection_max_page_size(ctx)
          ::Gitlab::Database::Aggregation::Graphql::AggregationConnection.effective_max_page_size(
            super,
            context: ctx
          )
        end
      end
      # rubocop:enable GraphQL/GraphqlName, Graphql/AuthorizeTypes
    end
  end
end
