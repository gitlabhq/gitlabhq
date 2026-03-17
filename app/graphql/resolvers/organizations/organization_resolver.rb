# frozen_string_literal: true

module Resolvers
  module Organizations
    class OrganizationResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_organization

      type Types::Organizations::OrganizationType, null: true

      argument :id,
        Types::GlobalIDType[::Organizations::Organization],
        required: false,
        description: 'ID of the organization.'

      def resolve(id: nil)
        id = current_organization.to_gid if id.nil?
        authorized_find!(id: id)
      end
    end
  end
end
