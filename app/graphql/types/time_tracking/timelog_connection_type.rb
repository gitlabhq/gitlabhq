# frozen_string_literal: true

module Types
  module TimeTracking
    # rubocop: disable Graphql/AuthorizeTypes
    class TimelogConnectionType < CountableConnectionType
      field :total_spent_time,
        GraphQL::Types::BigInt,
        null: false,
        description: 'Total time spent in seconds.'

      def total_spent_time
        relation = object.items

        # sometimes relation is an Array
        relation = relation.without_order if relation.respond_to?(:reorder)

        relation.sum(:time_spent)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
