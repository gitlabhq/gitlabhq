# frozen_string_literal: true

module Mutations
  module Ci
    module JobTokenScope
      class ClearAllowlistAutopopulations < BaseMutation
        graphql_name 'CiJobTokenScopeClearAllowlistAutopopulations'

        include FindsProject

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

          result = ::Ci::JobToken::ClearAutopopulatedAllowlistService.new(project, current_user).execute

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
