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

        argument :default_permissions, GraphQL::Types::Boolean,
          required: false,
          default_value: true,
          experiment: { milestone: '17.8' },
          description: 'Indicates whether default permissions are enabled (true) or fine-grained permissions are ' \
            'enabled (false).'

        argument :job_token_policies, [Types::Ci::JobTokenScope::PoliciesEnum],
          required: false,
          default_value: [],
          experiment: { milestone: '17.5' },
          description: 'List of policies added to the CI job token scope. Is ignored if ' \
            '`add_policies_to_ci_job_token` feature flag is disabled.'

        field :ci_job_token_scope_allowlist_entry,
          Types::Ci::JobTokenScope::AllowlistEntryType,
          null: true,
          experiment: { milestone: '17.6' },
          description: "Allowlist entry for the CI job token's access scope."

        field :ci_job_token_scope, # rubocop: disable GraphQL/ExtractType -- no value for now
          Types::Ci::JobTokenScopeType,
          null: true,
          description: "CI job token's access scope."

        def resolve(project_path:, target_path:, default_permissions:, job_token_policies:)
          project = authorized_find!(project_path)
          target = find_target_path(target_path)
          policies_enabled = Feature.enabled?(:add_policies_to_ci_job_token, project)
          # Use default permissions if policies feature isn't enabled.
          default = policies_enabled ? default_permissions : true

          result = ::Ci::JobTokenScope::AddGroupOrProjectService
            .new(project, current_user)
            .execute(target, default_permissions: default, policies: job_token_policies)

          if result.success?
            {
              ci_job_token_scope: ::Ci::JobToken::Scope.new(project),
              ci_job_token_scope_allowlist_entry: result.payload.values[0],
              errors: []
            }
          else
            {
              ci_job_token_scope: nil,
              ci_job_token_scope_allowlist_entry: nil,
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
