# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      # rubocop:disable GraphQL/GraphqlName -- connection
      class EngineResponseConnectionType < GraphQL::Types::Relay::BaseConnection # rubocop: disable Graphql/AuthorizeTypes -- handled in parent
        field :count, GraphQL::Types::Int, null: false,
          description: 'Total number of aggregated rows.'

        def count
          object.items.count
        end
      end
      # rubocop:enable GraphQL/GraphqlName
    end
  end
end
