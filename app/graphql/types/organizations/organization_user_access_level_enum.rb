# frozen_string_literal: true

module Types
  module Organizations
    class OrganizationUserAccessLevelEnum < BaseEnum
      graphql_name 'OrganizationUserAccessLevel'
      description 'Access level of an organization user'

      value 'DEFAULT', value: Gitlab::Access::GUEST, description: 'Guest access.', experiment: { milestone: '16.11' }
      value 'OWNER', value: Gitlab::Access::OWNER, description: 'Owner access.', experiment: { milestone: '16.11' }
    end
  end
end
