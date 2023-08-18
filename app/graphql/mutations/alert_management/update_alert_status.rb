# frozen_string_literal: true

module Mutations
  module AlertManagement
    class UpdateAlertStatus < Base
      graphql_name 'UpdateAlertStatus'

      argument :status, Types::AlertManagement::StatusEnum,
        required: true,
        description: 'Status to set the alert.'

      def resolve(project_path:, iid:, status:)
        alert = authorized_find!(project_path: project_path, iid: iid)
        result = update_status(alert, status)

        track_alert_events('incident_management_alert_status_changed', alert)

        prepare_response(result)
      end

      private

      def update_status(alert, status)
        ::AlertManagement::Alerts::UpdateService
          .new(alert, current_user, status: status)
          .execute
      end

      def prepare_response(result)
        {
          alert: result.payload[:alert],
          errors: result.errors
        }
      end
    end
  end
end
