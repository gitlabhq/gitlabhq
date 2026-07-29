# frozen_string_literal: true

module Mutations
  module Organizations
    class Restore < BaseMutation
      graphql_name 'OrganizationRestore'

      authorize :restore_organization
      authorize_granular_token permissions: :restore_organization, boundary: :instance, boundary_type: :instance

      argument :id,
        Types::GlobalIDType[::Organizations::Organization],
        required: true,
        description: 'ID of the organization to restore.'

      field :organization,
        ::Types::Organizations::OrganizationType,
        null: true,
        description: 'Restored organization.'

      def resolve(id:)
        organization = authorized_find!(id: id)

        result = ::Organizations::RestoreService.new(
          organization,
          current_user: current_user
        ).execute

        { organization: result.payload[:organization], errors: result.errors }
      end
    end
  end
end
