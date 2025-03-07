# frozen_string_literal: true

module Resolvers
  class GroupsResolver < BaseResolver
    include ResolvesGroups

    type Types::GroupType.connection_type, null: true

    argument :ids, [GraphQL::Types::ID],
      required: false,
      description: 'Filter groups by IDs.',
      prepare: ->(global_ids, _ctx) { GitlabSchema.parse_gids(global_ids, expected_type: ::Group).map(&:model_id) }

    argument :top_level_only, GraphQL::Types::Boolean,
      required: false,
      default_value: false,
      description: 'Only include top-level groups.'

    argument :owned_only, GraphQL::Types::Boolean,
      as: :owned,
      required: false,
      default_value: false,
      description: 'Only include groups where the current user has an owner role.'

    argument :search, GraphQL::Types::String,
      required: false,
      description: 'Search query for group name or group full path.'

    argument :sort, GraphQL::Types::String,
      required: false,
      description: "Sort order of results. Format: `<field_name>_<sort_direction>`, " \
        "for example: `id_desc` or `name_asc`",
      default_value: 'name_asc'

    argument :all_available, GraphQL::Types::Boolean,
      required: false,
      default_value: true,
      replace_null_with_default: true,
      description: <<~DESC
        When `true`, returns all accessible groups. When `false`, returns only groups where the user is a member.
        Unauthenticated requests always return all public groups. The `owned_only` argument takes precedence.
      DESC

    private

    def resolve_groups(**args)
      GroupsFinder
        .new(context[:current_user], args)
        .execute
    end
  end
end

Resolvers::GroupsResolver.prepend_mod_with('Resolvers::GroupsResolver')
