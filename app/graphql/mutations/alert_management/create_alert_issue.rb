# frozen_string_literal: true

module Mutations
  module AlertManagement
    class CreateAlertIssue < Base
      graphql_name 'CreateAlertIssue'

      def resolve(args)
        alert = authorized_find!(project_path: args[:project_path], iid: args[:iid])
        result = create_alert_issue(alert, current_user)

        prepare_response(alert, result)
      end

      private

      def create_alert_issue(alert, user)
        ::AlertManagement::CreateAlertIssueService.new(alert, user).execute
      end

      def prepare_response(alert, result)
        {
          alert: alert,
          issue: result.payload[:issue],
          errors: Array(result.message)
        }
      end
    end
  end
end
