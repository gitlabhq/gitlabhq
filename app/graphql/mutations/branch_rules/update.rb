# frozen_string_literal: true

module Mutations
  module BranchRules
    class Update < BaseMutation
      graphql_name 'BranchRuleUpdate'

      include FindsProject

      authorize :admin_project

      argument :id, ::Types::GlobalIDType[::ProtectedBranch],
        required: true,
        description: 'Global ID of the protected branch.'

      argument :name, GraphQL::Types::String,
        required: true,
        description: 'Branch name, with wildcards, for the branch rules.'

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path to the project that the branch is associated with.'

      field :branch_rule,
        Types::Projects::BranchRuleType,
        null: true,
        description: 'Branch rule after mutation.'

      def resolve(id:, project_path:, name:)
        protected_branch = ::Gitlab::Graphql::Lazy.force(GitlabSchema.object_from_id(id,
          expected_type: ::ProtectedBranch))
        raise_resource_not_available_error! unless protected_branch

        project = authorized_find!(project_path)

        protected_branch = ::ProtectedBranches::UpdateService.new(project, current_user,
          { name: name }).execute(protected_branch)

        if protected_branch.errors.empty?
          {
            branch_rule: ::Projects::BranchRule.new(project, protected_branch),
            errors: []
          }
        else
          { errors: errors_on_object(protected_branch) }
        end
      end
    end
  end
end
