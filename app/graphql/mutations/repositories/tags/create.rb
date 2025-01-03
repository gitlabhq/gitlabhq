# frozen_string_literal: true

module Mutations
  module Repositories
    module Tags
      class Create < BaseMutation
        graphql_name 'TagCreate'

        include FindsProject

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project full path the branch is associated with.'

        argument :name, GraphQL::Types::String,
          required: true,
          description: 'Name of the tag.'

        argument :ref,
          GraphQL::Types::String,
          required: true,
          description: 'Tag name or commit SHA to create tag from.'

        argument :message,
          GraphQL::Types::String,
          required: false,
          default_value: '',
          description: 'Tagging message.'

        field :tag,
          Types::Repositories::TagType,
          null: true,
          description: 'Tag after mutation.'

        authorize :admin_tag

        def resolve(project_path:, name:, ref:, message:)
          project = authorized_find!(project_path)

          result = ::Tags::CreateService.new(project, current_user)
                     .execute(name, ref, message)

          {
            tag: (result[:tag] if result[:status] == :success),
            errors: Array.wrap(result[:message])
          }
        end
      end
    end
  end
end
