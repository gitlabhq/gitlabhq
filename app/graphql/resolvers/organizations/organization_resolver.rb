# frozen_string_literal: true

module Resolvers
  module Organizations
    class OrganizationResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_organization

      type Types::Organizations::OrganizationType, null: true

      argument :id,
        Types::GlobalIDType[::Organizations::Organization],
        required: true,
        description: 'ID of the organization.'

      def resolve(id:)
        authorized_find!(id: id)
      end
    end
  end
end
