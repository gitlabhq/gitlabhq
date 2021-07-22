# frozen_string_literal: true

module Mutations
  module Issues
    class Move < Base
      graphql_name 'IssueMove'

      argument :target_project_path,
               GraphQL::Types::ID,
               required: true,
               description: 'The project to move the issue to.'

      def resolve(project_path:, iid:, target_project_path:)
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20816')

        issue = authorized_find!(project_path: project_path, iid: iid)
        source_project = issue.project
        target_project = resolve_project(full_path: target_project_path).sync

        begin
          moved_issue = ::Issues::MoveService.new(project: source_project, current_user: current_user).execute(issue, target_project)
        rescue ::Issues::MoveService::MoveError => error
          errors = error.message
        end

        {
          issue: moved_issue,
          errors: Array.wrap(errors)
        }
      end
    end
  end
end
