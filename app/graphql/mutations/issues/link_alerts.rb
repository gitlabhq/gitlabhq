# frozen_string_literal: true

module Mutations
  module Issues
    class LinkAlerts < Base
      graphql_name 'IssueLinkAlerts'

      argument :alert_references, [GraphQL::Types::String],
        required: true,
        description: 'Alerts references to be linked to the incident.'

      authorize :admin_issue

      def resolve(project_path:, iid:, alert_references:)
        issue = authorized_find!(project_path: project_path, iid: iid)

        ::IncidentManagement::LinkAlerts::CreateService.new(issue, current_user, alert_references).execute

        {
          issue: issue,
          errors: errors_on_object(issue)
        }
      end
    end
  end
end
