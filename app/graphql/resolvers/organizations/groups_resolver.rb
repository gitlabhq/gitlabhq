# frozen_string_literal: true

module Resolvers
  module Organizations
    class GroupsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include ResolvesGroups

      type Types::GroupType.connection_type, null: true

      authorize :read_group

      argument :search,
        GraphQL::Types::String,
        required: false,
        description: 'Search query for group name or full path.',
        alpha: { milestone: '16.4' }

      argument :sort,
        Types::Organizations::GroupSortEnum,
        description: 'Criteria to sort organization groups by.',
        required: false,
        default_value: { field: 'name', direction: :asc },
        alpha: { milestone: '16.4' }

      private

      def resolve_groups(**args)
        return Group.none if Feature.disabled?(:resolve_organization_groups, context[:current_user])

        ::Organizations::GroupsFinder
          .new(organization: object, current_user: context[:current_user], params: args)
          .execute
      end
    end
  end
end
