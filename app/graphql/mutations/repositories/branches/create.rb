# frozen_string_literal: true

module Mutations
  module Repositories
    module Branches
      class Create < BaseMutation
        graphql_name 'CreateBranch'

        include FindsProject

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project full path the branch is associated with.'

        argument :name, GraphQL::Types::String,
          required: true,
          description: 'Name of the branch.'

        argument :ref,
          GraphQL::Types::String,
          required: true,
          description: 'Branch name or commit SHA to create branch from.'

        field :branch,
          Types::BranchType,
          null: true,
          description: 'Branch after mutation.'

        authorize :push_code

        def resolve(project_path:, name:, ref:)
          project = authorized_find!(project_path)

          result = ::Branches::CreateService.new(project, current_user)
                     .execute(name, ref)

          {
            branch: (result[:branch] if result[:status] == :success),
            errors: Array.wrap(result[:message])
          }
        end
      end
    end
  end
end
