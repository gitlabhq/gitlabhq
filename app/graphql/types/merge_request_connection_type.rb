# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class MergeRequestConnectionType < Types::CountableConnectionType
    field :total_time_to_merge,
      GraphQL::Types::Float,
      null: true,
      description: 'Total sum of time to merge, in seconds, for the collection of merge requests.'

    # rubocop: disable CodeReuse/ActiveRecord
    def total_time_to_merge
      object.items.reorder(nil).total_time_to_merge
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
