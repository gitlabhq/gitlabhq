# frozen_string_literal: true

module Mutations
  module Issues
    class UnlinkAlert < Base
      graphql_name 'IssueUnlinkAlert'

      argument :alert_id, ::Types::GlobalIDType[::AlertManagement::Alert],
        required: true,
        description: 'Global ID of the alert to unlink from the incident.'

      authorize :admin_issue

      def resolve(project_path:, iid:, alert_id:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        alert = find_alert_by_gid(alert_id)

        result = ::IncidentManagement::LinkAlerts::DestroyService.new(issue, current_user, alert).execute

        {
          issue: issue,
          errors: result.errors
        }
      end

      private

      def find_alert_by_gid(alert_id)
        ::Gitlab::Graphql::Lazy.force(GitlabSchema.object_from_id(alert_id, expected_type: ::AlertManagement::Alert))
      end
    end
  end
end
