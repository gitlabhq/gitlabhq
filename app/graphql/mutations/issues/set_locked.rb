# frozen_string_literal: true

module Mutations
  module Issues
    class SetLocked < Base
      graphql_name 'IssueSetLocked'

      argument :locked,
               GraphQL::BOOLEAN_TYPE,
               required: true,
               description: 'Whether or not to lock discussion on the issue'

      def resolve(project_path:, iid:, locked:)
        issue = authorized_find!(project_path: project_path, iid: iid)

        ::Issues::UpdateService.new(issue.project, current_user, discussion_locked: locked)
          .execute(issue)

        {
          issue: issue,
          errors: errors_on_object(issue)
        }
      end
    end
  end
end
