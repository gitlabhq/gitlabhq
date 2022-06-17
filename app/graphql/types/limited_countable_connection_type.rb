# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class LimitedCountableConnectionType < GraphQL::Types::Relay::BaseConnection
    COUNT_LIMIT = 1000
    COUNT_DESCRIPTION = "Limited count of collection. Returns limit + 1 for counts greater than the limit."

    field :count, GraphQL::Types::Int, null: false, description: COUNT_DESCRIPTION do
      argument :limit, GraphQL::Types::Int,
        required: false, default_value: COUNT_LIMIT,
        validates: { numericality: { greater_than: 0, less_than_or_equal_to: COUNT_LIMIT } },
        description: "Limit value to be applied to the count query. Default is 1000."
    end

    def count(limit:)
      relation = object.items

      if relation.respond_to?(:page)
        relation.page.total_count_with_limit(:all, limit: limit)
      else
        [relation.size, limit.next].min
      end
    end
  end
end
