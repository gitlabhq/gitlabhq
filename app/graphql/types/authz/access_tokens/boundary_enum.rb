# frozen_string_literal: true

module Types
  module Authz
    module AccessTokens
      class BoundaryEnum < BaseEnum
        graphql_name 'PermissionBoundary'

        description 'Type of resource that the permission can be applied to.'

        value 'GROUP', value: 'group', description: 'Group.'
        value 'PROJECT', value: 'project', description: 'Project.'
        value 'USER', value: 'user', description: 'User.'
        value 'INSTANCE', value: 'instance', description: 'Instance.'
      end
    end
  end
end
