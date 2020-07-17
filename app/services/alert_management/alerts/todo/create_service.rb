# frozen_string_literal: true

module AlertManagement
  module Alerts
    module Todo
      class CreateService
        # @param alert [AlertManagement::Alert]
        # @param current_user [User]
        def initialize(alert, current_user)
          @alert = alert
          @current_user = current_user
        end

        def execute
          return error_no_permissions unless allowed?

          todos = TodoService.new.mark_todo(alert, current_user)
          todo = todos&.first

          return error_existing_todo unless todo

          success(todo)
        end

        private

        attr_reader :alert, :current_user

        def allowed?
          current_user&.can?(:update_alert_management_alert, alert)
        end

        def error(message)
          ServiceResponse.error(payload: { alert: alert, todo: nil }, message: message)
        end

        def success(todo)
          ServiceResponse.success(payload: { alert: alert, todo: todo })
        end

        def error_no_permissions
          error(_('You have insufficient permissions to create a Todo for this alert'))
        end

        def error_existing_todo
          error(_('You already have pending todo for this alert'))
        end
      end
    end
  end
end
