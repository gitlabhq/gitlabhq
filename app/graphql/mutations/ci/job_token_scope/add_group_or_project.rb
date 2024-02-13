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

        field :ci_job_token_scope,
          Types::Ci::JobTokenScopeType,
          null: true,
          description: "CI job token's access scope."

        def resolve(project_path:, target_path:)
          project = authorized_find!(project_path)

          target = find_target_path(target_path)

          result = ::Ci::JobTokenScope::AddGroupOrProjectService
            .new(project, current_user)
            .execute(target)

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
