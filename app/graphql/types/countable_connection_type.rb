# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class CountableConnectionType < GraphQL::Types::Relay::BaseConnection
    field :count, GraphQL::Types::Int, null: false,
      description: 'Total count of collection.'

    def count
      relation = object.items

      # sometimes relation is an Array
      relation = relation.without_order if relation.respond_to?(:reorder)

      if relation.try(:group_values).present?
        relation.size.keys.size
      else
        relation.size
      end
    end
  end
end
