# frozen_string_literal: true

module Resolvers
  class NestedGroupsResolver < BaseResolver
    include ResolvesGroups

    type Types::GroupType, null: true

    argument :include_parent_descendants, GraphQL::Types::Boolean,
      required: false,
      description: 'List of descendant groups of the parent group.',
      default_value: true

    argument :owned, GraphQL::Types::Boolean,
      required: false,
      description: 'Limit result to groups owned by authenticated user.'

    argument :search, GraphQL::Types::String,
      required: false,
      description: 'Search query for group name or group full path.'

    argument :ids, [GraphQL::Types::ID],
      required: false,
      description: 'Filter groups by IDs.',
      prepare: ->(global_ids, _ctx) {
        GitlabSchema.parse_gids(global_ids, expected_type: ::Group).map(&:model_id)
      }

    argument :sort, Types::Namespaces::GroupSortEnum,
      required: false,
      description: 'Sort groups by given criteria.',
      default_value: :name_asc

    alias_method :parent, :object

    private

    def resolve_groups(args)
      return Group.none unless parent.present?

      GroupsFinder
        .new(context[:current_user], args.merge(parent: parent))
        .execute
    end
  end
end
