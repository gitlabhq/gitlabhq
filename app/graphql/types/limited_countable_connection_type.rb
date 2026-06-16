# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class LimitedCountableConnectionType < GraphQL::Types::Relay::BaseConnection
    include CountableConnectionHelper

    COUNT_LIMIT = 1000
    COUNT_DESCRIPTION = "Returns the number of items in the connection up to a limit. " \
      "If the number is greater than the limit, returns `limit + 1`."

    field :count, GraphQL::Types::Int, null: false, description: COUNT_DESCRIPTION do
      argument :limit, GraphQL::Types::Int,
        required: false, default_value: COUNT_LIMIT,
        validates: { numericality: { greater_than: 0, less_than_or_equal_to: COUNT_LIMIT } },
        description: "Limit value to be applied to the count query. Default is 1000."
    end

    def count(limit:)
      limited_count(object.items, limit)
    end
  end
end
