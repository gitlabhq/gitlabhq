# frozen_string_literal: true

module Mutations
  module Ci
    module JobTokenScope
      class RemoveGroup < BaseMutation
        graphql_name 'CiJobTokenScopeRemoveGroup'

        include FindsProject

        authorize :admin_project

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project that the CI job token scope belongs to.'

        argument :target_group_path, GraphQL::Types::ID,
          required: true,
          description: 'Group to be removed from the CI job token scope.'

        field :ci_job_token_scope_allowlist_entry,
          Types::Ci::JobTokenScope::AllowlistEntryType,
          null: true,
          experiment: { milestone: '17.6' },
          description: "Allowlist entry for the CI job token's access scope."

        field :ci_job_token_scope, # rubocop: disable GraphQL/ExtractType -- no value for now
          Types::Ci::JobTokenScopeType,
          null: true,
          description: "CI job token's access scope."

        def resolve(project_path:, target_group_path:)
          project = authorized_find!(project_path)
          target_group = Group.find_by_full_path(target_group_path)

          result = ::Ci::JobTokenScope::RemoveGroupService
            .new(project, current_user)
            .execute(target_group)

          if result.success?
            {
              ci_job_token_scope: ::Ci::JobToken::Scope.new(project),
              ci_job_token_scope_allowlist_entry: result.payload,
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
      end
    end
  end
end
