# frozen_string_literal: true

module Mutations
  module BranchRules
    class Create < BaseMutation
      graphql_name 'BranchRuleCreate'

      authorize :create_branch_rule

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path to the project that the branch is associated with.'

      argument :name, GraphQL::Types::String,
        required: true,
        description: 'Branch name, with wildcards, for the branch rules.'

      field :branch_rule,
        Types::Projects::BranchRuleType,
        null: true,
        description: 'Branch rule after mutation.'

      def resolve(project_path:, name:)
        project = authorized_find!(project_path)

        service_params = protected_branch_params(name)
        protected_branch = ::ProtectedBranches::CreateService.new(project, current_user, service_params).execute

        if protected_branch.persisted?
          {
            branch_rule: ::Projects::BranchRule.new(project, protected_branch),
            errors: []
          }
        else
          { errors: errors_on_object(protected_branch) }
        end
      rescue Gitlab::Access::AccessDeniedError
        raise_resource_not_available_error!
      end

      def protected_branch_params(name)
        {
          name: name,
          push_access_levels_attributes: access_level_attributes(:push),
          merge_access_levels_attributes: access_level_attributes(:merge)
        }
      end

      def access_level_attributes(type)
        ::ProtectedRefs::AccessLevelParams.new(
          type,
          {},
          with_defaults: true
        ).access_levels
      end

      private

      def find_object(full_path)
        Project.find_by_full_path(full_path)
      end
    end
  end
end
