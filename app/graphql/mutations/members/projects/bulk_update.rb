# frozen_string_literal: true

module Mutations
  module Members
    module Projects
      class BulkUpdate < BulkUpdateBase
        graphql_name 'ProjectMemberBulkUpdate'
        description 'Updates multiple members of a project. ' \
          'To use this mutation, you must have at least the Maintainer role.'

        authorize :admin_project_member

        field :project_members,
          [Types::ProjectMemberType],
          null: true,
          description: 'Project members after mutation.'

        argument :project_id,
          ::Types::GlobalIDType[::Project],
          required: true,
          description: 'Global ID of the project.'

        def source_type
          ::Project
        end
      end
    end
  end
end
