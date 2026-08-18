# frozen_string_literal: true

module Mutations
  module Organizations
    module OrganizationUsers
      class Delete < BaseMutation
        graphql_name 'OrganizationUserDelete'

        authorize :delete_organization_user
        authorize_granular_token permissions: :delete_organization_user, boundary: :instance,
          boundary_type: :instance

        argument :id,
          Types::GlobalIDType[::Organizations::OrganizationUser],
          required: true,
          description: 'ID of the organization user to delete.'

        field :organization_user,
          ::Types::Organizations::OrganizationUserType,
          null: true,
          description: 'Organization user that was deleted.',
          experiment: { milestone: '19.3' }

        def resolve(id:)
          organization_user = authorized_find!(id: id)

          result = ::Organizations::OrganizationUsers::DestroyService.new(
            organization_user,
            current_user: current_user
          ).execute

          { organization_user: result[:organization_user], errors: result.errors }
        end
      end
    end
  end
end
