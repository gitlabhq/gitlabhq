# frozen_string_literal: true

module Mutations
  module Ci
    module JobTokenScope
      class RemoveProject < BaseMutation
        include FindsProject

        graphql_name 'CiJobTokenScopeRemoveProject'

        authorize :admin_project

        argument :project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'The project that the CI job token scope belongs to.'

        argument :target_project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'The project to be removed from the CI job token scope.'

        field :ci_job_token_scope,
          Types::Ci::JobTokenScopeType,
          null: true,
          description: "The CI job token's scope of access."

        def resolve(project_path:, target_project_path:)
          project = authorized_find!(project_path)
          target_project = Project.find_by_full_path(target_project_path)

          result = ::Ci::JobTokenScope::RemoveProjectService
            .new(project, current_user)
            .execute(target_project)

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
      end
    end
  end
end
