# frozen_string_literal: true

module Resolvers
  module Organizations
    class GroupsResolver < Resolvers::GroupsResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::GroupType.connection_type, null: true

      authorize :read_group

      private

      alias_method :organization, :object

      def resolve_groups(**args)
        return Group.none if Feature.disabled?(:resolve_organization_groups, current_user)

        super
      end

      def finder_params(args)
        extra_args = { organization: organization, include_ancestors: false, all_available: false }

        super.merge(extra_args)
      end
    end
  end
end
