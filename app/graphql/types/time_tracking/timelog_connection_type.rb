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
        # rubocop: disable CodeReuse/ActiveRecord
        relation = object.items

        # sometimes relation is an Array
        relation = relation.reorder(nil) if relation.respond_to?(:reorder)
        # rubocop: enable CodeReuse/ActiveRecord

        relation.sum(:time_spent)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
