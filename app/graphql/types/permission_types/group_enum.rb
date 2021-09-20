# frozen_string_literal: true

module Types
  module PermissionTypes
    class GroupEnum < BaseEnum
      graphql_name 'GroupPermission'
      description 'User permission on groups'

      value 'CREATE_PROJECTS', value: :create_projects, description: 'Groups where the user can create projects.'
    end
  end
end
