# frozen_string_literal: true

module Resolvers
  module Organizations
    class OrganizationUsersResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead

      type Types::Organizations::OrganizationUserType.connection_type, null: true

      authorize :read_organization_user

      alias_method :organization, :object

      def resolve_with_lookahead
        authorize!(object)

        apply_lookahead(organization_users)
      end

      private

      def organization_users
        ::Organizations::OrganizationUsersFinder
          .new(organization: organization, current_user: context[:current_user])
          .execute
      end

      def preloads
        {
          user: [:user]
        }
      end
    end
  end
end
