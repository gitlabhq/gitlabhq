# frozen_string_literal: true

module Mutations
  module Ci
    module JobTokenScope
      class AddProject < BaseMutation
        graphql_name 'CiJobTokenScopeAddProject'

        include FindsProject

        authorize :admin_project

        argument :project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Project that the CI job token scope belongs to.'

        argument :target_project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Project to be added to the CI job token scope.'

        argument :direction,
                 ::Types::Ci::JobTokenScope::DirectionEnum,
                 required: false,
                 deprecated: {
                   reason: 'Outbound job token scope is being removed. This field can now only be set to INBOUND',
                   milestone: '16.0'
                 },
                 description: 'Direction of access, which defaults to INBOUND.'

        field :ci_job_token_scope,
              Types::Ci::JobTokenScopeType,
              null: true,
              description: "CI job token's access scope."

        def resolve(project_path:, target_project_path:, direction: nil)
          project = authorized_find!(project_path)
          target_project = Project.find_by_full_path(target_project_path)

          if direction == :outbound
            raise Gitlab::Graphql::Errors::ArgumentError, 'direction: OUTBOUND scope entries can only be removed. ' \
                                                          'Only INBOUND scope can be expanded.'
          end

          direction ||= :inbound

          result = ::Ci::JobTokenScope::AddProjectService
            .new(project, current_user)
            .execute(target_project, direction: direction)

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
