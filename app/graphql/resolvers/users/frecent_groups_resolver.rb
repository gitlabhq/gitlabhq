# frozen_string_literal: true

module Resolvers
  module Users
    class FrecentGroupsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type [Types::GroupType], null: true

      ORGANIZATION_UNAVAILABLE_ERROR =
        'scopeToOrganization was requested but no current organization could be determined.'

      argument :scope_to_organization, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Limits results to groups in the current organization.'

      def resolve(scope_to_organization: false)
        return unless current_user.present?

        organization_id = requested_organization_id if scope_to_organization

        ::Users::GroupVisit.frecent_groups(user_id: current_user.id, organization_id: organization_id)
      end

      private

      # Raise rather than fall through to an unscoped query: a nil organization here
      # would be indistinguishable from the caller never asking to scope at all.
      def requested_organization_id
        return current_organization.id if current_organization

        raise Gitlab::Graphql::Errors::ArgumentError, ORGANIZATION_UNAVAILABLE_ERROR
      end
    end
  end
end
