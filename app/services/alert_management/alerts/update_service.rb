# frozen_string_literal: true

module AlertManagement
  module Alerts
    class UpdateService
      include Gitlab::Utils::StrongMemoize

      # @param alert [AlertManagement::Alert]
      # @param current_user [User]
      # @param params [Hash] Attributes of the alert
      def initialize(alert, current_user, params)
        @alert = alert
        @current_user = current_user
        @params = params
      end

      def execute
        return error_no_permissions unless allowed?
        return error_no_updates if params.empty?

        filter_assignees

        if alert.update(params)
          assign_todo
          success
        else
          error(alert.errors.full_messages.to_sentence)
        end
      end

      private

      attr_reader :alert, :current_user, :params

      def assign_todo
        return unless assignee

        todo_service.assign_alert(alert, assignee)
      end

      def allowed?
        current_user.can?(:update_alert_management_alert, alert)
      end

      def filter_assignees
        return if params[:assignees].nil?

        params[:assignees] = Array(assignee)
      end

      def assignee
        strong_memoize(:assignee) do
          # Take first assignee while multiple are not currently supported
          params[:assignees]&.first
        end
      end

      def todo_service
        strong_memoize(:todo_service) do
          TodoService.new
        end
      end

      def success
        ServiceResponse.success(payload: { alert: alert })
      end

      def error(message)
        ServiceResponse.error(payload: { alert: alert }, message: message)
      end

      def error_no_permissions
        error(_('You have no permissions'))
      end

      def error_no_updates
        error(_('Please provide attributes to update'))
      end
    end
  end
end
