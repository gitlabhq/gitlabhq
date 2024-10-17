# frozen_string_literal: true

module Mutations
  module Ci
    module JobTokenScope
      class AddGroupOrProject < BaseMutation
        graphql_name 'CiJobTokenScopeAddGroupOrProject'

        include FindsProject

        authorize :admin_project

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project that the CI job token scope belongs to.'

        argument :target_path, GraphQL::Types::ID,
          required: true,
          description: 'Group or project to be added to the CI job token scope.'

        argument :job_token_policies, [Types::Ci::JobTokenScope::PoliciesEnum],
          required: false,
          default_value: [],
          alpha: { milestone: '17.5' },
          description: 'List of policies added to the CI job token scope. Is ignored if ' \
            '`add_policies_to_ci_job_token` feature flag is disabled.'

        field :ci_job_token_scope,
          Types::Ci::JobTokenScopeType,
          null: true,
          description: "CI job token's access scope."

        def resolve(args)
          project = authorized_find!(args[:project_path])

          target = find_target_path(args[:target_path])

          args.delete(:job_token_policies) unless Feature.enabled?(:add_policies_to_ci_job_token, project)

          result = ::Ci::JobTokenScope::AddGroupOrProjectService
            .new(project, current_user)
            .execute(target, policies: args[:job_token_policies])

          if result.success?
            {
              ci_job_token_scope: ::Ci::JobToken::Scope.new(project),
              errors: []
            }
          else
            {
              ci_job_token_scope: nil,
              errors: [result.message]
            }
          end
        end

        private

        def find_target_path(target_path)
          ::Group.find_by_full_path(target_path) ||
            ::Project.find_by_full_path(target_path)
        end
      end
    end
  end
end
