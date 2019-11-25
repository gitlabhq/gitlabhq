# frozen_string_literal: true

module Mutations
  module Issues
    class SetDueDate < Base
      graphql_name 'IssueSetDueDate'

      argument :due_date,
               Types::TimeType,
               required: true,
               description: 'The desired due date for the issue'

      def resolve(project_path:, iid:, due_date:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        ::Issues::UpdateService.new(project, current_user, due_date: due_date)
          .execute(issue)

        {
          issue: issue,
          errors: issue.errors.full_messages
        }
      end
    end
  end
end
