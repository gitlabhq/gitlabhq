# frozen_string_literal: true

module Mutations
  module Organizations
    module OrganizationUsers
      # rubocop:disable GraphQL/GraphqlName -- This is a base mutation so name is not needed here
      class Base < BaseMutation
        field :organization_user,
          ::Types::Organizations::OrganizationUserType,
          null: true,
          description: 'Organization user after mutation.',
          experiment: { milestone: '17.5' }

        argument :access_level,
          ::Types::Organizations::OrganizationUserAccessLevelEnum,
          required: true,
          description: 'Access level to update the organization user to.'
      end
      # rubocop:enable GraphQL/GraphqlName
    end
  end
end
