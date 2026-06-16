# frozen_string_literal: true

module Mutations
  module Organizations
    class Delete < Base
      graphql_name 'OrganizationDelete'

      authorize :delete_organization
      authorize_granular_token permissions: :delete_organization, boundary: :instance, boundary_type: :instance

      argument :id,
        Types::GlobalIDType[::Organizations::Organization],
        required: true,
        description: 'ID of the organization to soft-delete.'

      field :organization,
        Types::Organizations::OrganizationType,
        null: true,
        description: 'Soft-deleted organization.'

      def resolve(id:)
        organization = authorized_find!(id: id)

        result = ::Organizations::SoftDeleteService.new(
          organization,
          current_user: current_user
        ).execute

        { organization: result.payload[:organization], errors: result.errors }
      end
    end
  end
end
