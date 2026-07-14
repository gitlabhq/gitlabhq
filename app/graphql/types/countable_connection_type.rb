# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class CountableConnectionType < GraphQL::Types::Relay::BaseConnection
    include CountableConnectionHelper

    COUNT_DESCRIPTION = "Total count of collection. Returns limit + 1 for counts greater than the limit."

    field :count, GraphQL::Types::Int, null: false, description: COUNT_DESCRIPTION do
      argument :limit, GraphQL::Types::Int,
        required: false,
        validates: { numericality: { greater_than: 0 } },
        description: "Limit applied to the count query, returns limit + 1. When not provided, returns the exact count."
    end

    def count(limit: nil)
      relation = object.items

      precomputed_count = relation.try(:precomputed_total_count)
      return resolve_precomputed_count(precomputed_count, limit) if precomputed_count

      resolve_count(relation, limit)
    end

    private

    def resolve_precomputed_count(precomputed_count, limit)
      return precomputed_count unless limit

      [precomputed_count, limit.next].min
    end

    def resolve_count(relation, limit)
      if limit
        # Limited counting for performance
        limited_count(relation, limit)
      else
        # Existing unlimited counting logic
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
end
