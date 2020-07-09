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
        @param_errors = []
      end

      def execute
        return error_no_permissions unless allowed?

        filter_params
        return error_invalid_params if param_errors.any?

        # Save old assignees for system notes
        old_assignees = alert.assignees.to_a

        if alert.update(params)
          handle_changes(old_assignees: old_assignees)

          success
        else
          error(alert.errors.full_messages.to_sentence)
        end
      end

      private

      attr_reader :alert, :current_user, :params, :param_errors
      delegate :resolved?, to: :alert

      def allowed?
        current_user&.can?(:update_alert_management_alert, alert)
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

      def error_invalid_params
        error(param_errors.to_sentence)
      end

      def add_param_error(message)
        param_errors << message
      end

      def filter_params
        param_errors << _('Please provide attributes to update') if params.empty?

        filter_status
        filter_assignees
      end

      def handle_changes(old_assignees:)
        handle_assignement(old_assignees) if params[:assignees]
        handle_status_change if params[:status_event]
      end

      # ----- Assignee-related behavior ------
      def filter_assignees
        return if params[:assignees].nil?

        # Always take first assignee while multiple are not currently supported
        params[:assignees] = Array(params[:assignees].first)

        param_errors << _('Assignee has no permissions') if unauthorized_assignees?
      end

      def unauthorized_assignees?
        params[:assignees]&.any? { |user| !user.can?(:read_alert_management_alert, alert) }
      end

      def handle_assignement(old_assignees)
        assign_todo
        add_assignee_system_note(old_assignees)
      end

      def assign_todo
        todo_service.assign_alert(alert, current_user)
      end

      def add_assignee_system_note(old_assignees)
        SystemNoteService.change_issuable_assignees(alert, alert.project, current_user, old_assignees)
      end

      # ------ Status-related behavior -------
      def filter_status
        return unless status = params.delete(:status)

        status_key = AlertManagement::Alert::STATUSES.key(status)
        status_event = AlertManagement::Alert::STATUS_EVENTS[status_key]

        unless status_event
          param_errors << _('Invalid status')
          return
        end

        params[:status_event] = status_event
      end

      def handle_status_change
        add_status_change_system_note
        resolve_todos if resolved?
      end

      def add_status_change_system_note
        SystemNoteService.change_alert_status(alert, current_user)
      end

      def resolve_todos
        todo_service.resolve_todos_for_target(alert, current_user)
      end
    end
  end
end
