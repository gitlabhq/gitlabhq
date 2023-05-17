# frozen_string_literal: true

module Types
  module PermissionTypes
    class GroupEnum < BaseEnum
      graphql_name 'GroupPermission'
      description 'User permission on groups'

      value 'CREATE_PROJECTS', value: :create_projects, description: 'Groups where the user can create projects.'
      value 'TRANSFER_PROJECTS',
        value: :transfer_projects,
        description: 'Groups where the user can transfer projects to.'
      value 'IMPORT_PROJECTS',
        value: :import_projects,
        description: 'Groups where the user can import projects to.'
    end
  end
end
