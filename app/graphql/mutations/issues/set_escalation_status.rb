# frozen_string_literal: true

module Mutations
  module Issues
    class SetEscalationStatus < Base
      graphql_name 'IssueSetEscalationStatus'

      argument :status, Types::IncidentManagement::EscalationStatusEnum,
        required: true,
        description: 'Set the escalation status.'

      def resolve(project_path:, iid:, status:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        authorize_escalation_status!(project)
        check_feature_availability!(issue)

        ::Issues::UpdateService.new(
          container: project,
          current_user: current_user,
          params: { escalation_status: { status: status } }
        ).execute(issue)

        {
          issue: issue,
          errors: errors_on_object(issue)
        }
      end

      private

      def authorize_escalation_status!(project)
        return if Ability.allowed?(current_user, :update_escalation_status, project)

        raise_resource_not_available_error!
      end

      def check_feature_availability!(issue)
        return if issue.supports_escalation?

        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature unavailable for provided issue'
      end
    end
  end
end
