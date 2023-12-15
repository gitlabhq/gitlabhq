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

      alias_method :organization, :object

      def resolve_groups(**args)
        return Group.none if Feature.disabled?(:resolve_organization_groups, current_user)

        extra_args = { organization: organization, include_ancestors: false, all_available: false }
        groups = GroupsFinder.new(current_user, args.merge(extra_args)).execute

        args[:sort] ||= { field: 'name', direction: :asc }
        field = args[:sort][:field]
        direction = args[:sort][:direction]
        groups.sort_by_attribute("#{field}_#{direction}")
      end
    end
  end
end
