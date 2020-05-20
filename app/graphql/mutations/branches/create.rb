# frozen_string_literal: true

module Mutations
  module Branches
    class Create < BaseMutation
      include Mutations::ResolvesProject

      graphql_name 'CreateBranch'

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'Project full path the branch is associated with'

      argument :name, GraphQL::STRING_TYPE,
               required: true,
               description: 'Name of the branch'

      argument :ref,
               GraphQL::STRING_TYPE,
               required: true,
               description: 'Branch name or commit SHA to create branch from'

      field :branch,
            Types::BranchType,
            null: true,
            description: 'Branch after mutation'

      authorize :push_code

      def resolve(project_path:, name:, ref:)
        project = authorized_find!(full_path: project_path)

        context.scoped_set!(:branch_project, project)

        result = ::Branches::CreateService.new(project, current_user)
                   .execute(name, ref)

        {
          branch: (result[:branch] if result[:status] == :success),
          errors: Array.wrap(result[:message])
        }
      end

      private

      def find_object(full_path:)
        resolve_project(full_path: full_path)
      end
    end
  end
end
