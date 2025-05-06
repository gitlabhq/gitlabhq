# frozen_string_literal: true

module Mutations
  module Issues
    class Move < Base
      graphql_name 'IssueMove'

      argument :target_project_path,
        GraphQL::Types::ID,
        required: true,
        description: 'Project to move the issue to.'

      def resolve(project_path:, iid:, target_project_path:)
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20816')

        issue = authorized_find!(project_path: project_path, iid: iid)
        target_project = resolve_project(full_path: target_project_path).sync

        begin
          response = ::WorkItems::DataSync::MoveService.new(
            work_item: issue, current_user: current_user,
            target_namespace: target_project.project_namespace
          ).execute

          errors = response.message if response.error?
          moved_issue = response.payload[:work_item]
        end

        {
          issue: moved_issue,
          errors: Array.wrap(errors)
        }
      end
    end
  end
end
