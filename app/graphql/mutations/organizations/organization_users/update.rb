# frozen_string_literal: true

module Mutations
  module Organizations
    module OrganizationUsers
      class Update < Base
        graphql_name 'OrganizationUserUpdate'

        authorize :admin_organization

        argument :id,
          Types::GlobalIDType[::Organizations::OrganizationUser],
          required: true,
          description: 'ID of the organization user to mutate.'

        def resolve(id:, **args)
          organization_user = authorized_find!(id: id)

          result = ::Organizations::OrganizationUsers::UpdateService.new(
            organization_user,
            current_user: current_user,
            params: args
          ).execute

          { organization_user: result.payload[:organization_user], errors: result.errors }
        end
      end
    end
  end
end
