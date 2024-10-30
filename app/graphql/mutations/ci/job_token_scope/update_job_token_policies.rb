# frozen_string_literal: true

module Mutations
  module Ci
    module JobTokenScope
      class UpdateJobTokenPolicies < BaseMutation
        graphql_name 'CiJobTokenScopeUpdatePolicies'

        include FindsProject

        authorize :admin_project

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project that the CI job token scope belongs to.'

        argument :target_path, GraphQL::Types::ID,
          required: true,
          description: 'Group or project that the CI job token targets.'

        argument :job_token_policies, [Types::Ci::JobTokenScope::PoliciesEnum],
          required: true,
          description: 'List of policies added to the CI job token scope.'

        field :ci_job_token_scope,
          Types::Ci::JobTokenScopeType,
          null: true,
          description: 'Updated CI job token access scope.'

        def resolve(project_path:, target_path:, job_token_policies:)
          project = authorized_find!(project_path)
          target = find_target_using_path(target_path)

          unless Feature.enabled?(:add_policies_to_ci_job_token, project)
            raise_resource_not_available_error! '`add_policies_to_ci_job_token` feature flag is disabled.'
          end

          result = ::Ci::JobTokenScope::UpdatePoliciesService
            .new(project, current_user)
            .execute(target, job_token_policies)

          {
            ci_job_token_scope: ::Ci::JobToken::Scope.new(project),
            errors: result.errors
          }
        end

        private

        def find_target_using_path(target_path)
          ::Group.find_by_full_path(target_path) ||
            ::Project.find_by_full_path(target_path)
        end
      end
    end
  end
end
