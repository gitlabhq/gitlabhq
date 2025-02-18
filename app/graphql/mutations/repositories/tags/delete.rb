# frozen_string_literal: true

module Mutations
  module Repositories
    module Tags
      class Delete < BaseMutation
        graphql_name 'TagDelete'

        include FindsProject

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project full path the branch is associated with.'

        argument :name, GraphQL::Types::String,
          required: true,
          description: 'Name of the tag.'

        field :tag,
          Types::Repositories::TagType,
          null: true,
          description: 'Tag after mutation.'

        authorize :admin_tag

        def resolve(project_path:, name:)
          project = authorized_find!(project_path)

          result = ::Tags::DestroyService.new(project, current_user)
                     .execute(name)
          {
            tag: nil,
            errors: result[:status] == :success ? [] : Array.wrap(result[:message])
          }
        end
      end
    end
  end
end
