# frozen_string_literal: true

module Mutations
  module Issues
    class SetSeverity < Base
      graphql_name 'IssueSetSeverity'

      argument :severity, Types::IssuableSeverityEnum, required: true,
               description: 'Set the incident severity level.'

      def resolve(project_path:, iid:, severity:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        ::Issues::UpdateService.new(project: project, current_user: current_user, params: { severity: severity })
          .execute(issue)

        {
          issue: issue,
          errors: errors_on_object(issue)
        }
      end
    end
  end
end
