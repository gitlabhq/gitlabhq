# frozen_string_literal: true

module Mutations
  module Issues
    class SetDueDate < Base
      graphql_name 'IssueSetDueDate'

      argument :due_date,
        Types::TimeType,
        required: :nullable,
        description: 'Desired due date for the issue. Due date is removed if null.'

      def resolve(project_path:, iid:, due_date:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        ::Issues::UpdateService.new(container: project, current_user: current_user, params: { due_date: due_date })
          .execute(issue)

        {
          issue: issue,
          errors: errors_on_object(issue)
        }
      end
    end
  end
end
