# frozen_string_literal: true

module Resolvers
  class GroupsResolver < BaseResolver
    include ResolvesGroups

    type Types::GroupType.connection_type, null: true

    argument :search, GraphQL::Types::String,
             required: false,
             description: 'Search query for group name or group full path.'

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def resolve_groups(**args)
      GroupsFinder
        .new(context[:current_user], args)
        .execute
        .reorder(name: :asc)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
