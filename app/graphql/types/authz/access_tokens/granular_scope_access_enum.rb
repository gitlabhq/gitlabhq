# frozen_string_literal: true

module Types
  module Authz
    module AccessTokens
      class GranularScopeAccessEnum < BaseEnum
        graphql_name 'AccessTokenGranularScopeAccess'

        description 'Access configured on a granular scope.'

        value 'PERSONAL_PROJECTS',
          value: 'personal_projects',
          description: 'Grants access to resources belonging to all personal projects of a user.'

        value 'ALL_MEMBERSHIPS',
          value: 'all_memberships',
          description: 'Grants access to resources belonging to all groups and projects the user is a member of.'

        value 'SELECTED_MEMBERSHIPS',
          value: 'selected_memberships',
          description: 'Grants access to resources belonging to selected groups and projects the user is a member of.'

        value 'USER',
          value: 'user',
          description: 'Grants access to standalone user-level resources.'

        value 'INSTANCE',
          value: 'instance',
          description: 'Grants access to standalone instance-level resources.'
      end
    end
  end
end
