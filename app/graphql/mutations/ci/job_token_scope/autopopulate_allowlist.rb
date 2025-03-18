# frozen_string_literal: true

module Mutations
  module Ci
    module JobTokenScope
      class AutopopulateAllowlist < BaseMutation
        graphql_name 'CiJobTokenScopeAutopopulateAllowlist'

        include FindsProject
        include Gitlab::InternalEventsTracking

        authorize :admin_project

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project in which to autopopulate the allowlist.'

        field :status,
          GraphQL::Types::String,
          null: false,
          description: "Status of the autopopulation process."

        def resolve(project_path:)
          project = authorized_find!(project_path)

          track_internal_event(
            'ci_job_token_autopopulate_allowlist',
            user: current_user,
            project: project,
            additional_properties: {
              label: 'ui'
            }
          )

          result = ::Ci::JobToken::ClearAutopopulatedAllowlistService.new(project, current_user).execute
          result = ::Ci::JobToken::AutopopulateAllowlistService.new(project, current_user).execute if result.success?

          if result.success?
            { status: "complete", errors: [] }
          else
            { status: "error", errors: [result.message] }
          end
        end
      end
    end
  end
end
