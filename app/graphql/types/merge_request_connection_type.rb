# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class MergeRequestConnectionType < Types::LimitedCountableConnectionType
    field :total_time_to_merge,
      GraphQL::Types::Float,
      null: true,
      description: 'Total sum of time to merge, in seconds, for the collection of merge requests.'

    def total_time_to_merge
      object.items.without_order.total_time_to_merge
    end
  end
end
