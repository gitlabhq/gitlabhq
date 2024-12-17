# frozen_string_literal: true

module Mutations
  module Branches # rubocop:disable Gitlab/BoundedContexts -- Existing module
    class Delete < BaseMutation
      graphql_name 'BranchDelete'

      include FindsProject

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Project full path the branch is associated with.'

      argument :name, GraphQL::Types::String,
        required: true,
        description: 'Name of the branch.'

      field :branch,
        Types::BranchType,
        null: true,
        description: 'Branch after mutation.'

      authorize :push_code

      def resolve(project_path:, name:)
        project = authorized_find!(project_path)

        result = ::Branches::DeleteService.new(project, current_user).execute(name)

        {
          branch: (result.payload[:branch] if result.error?),
          errors: result.errors
        }
      end
    end
  end
end
