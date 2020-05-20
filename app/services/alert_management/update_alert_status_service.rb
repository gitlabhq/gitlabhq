# frozen_string_literal: true

module AlertManagement
  class UpdateAlertStatusService
    include Gitlab::Utils::StrongMemoize

    # @param alert [AlertManagement::Alert]
    # @param user [User]
    # @param status [Integer] Must match a value from AlertManagement::Alert::STATUSES
    def initialize(alert, user, status)
      @alert = alert
      @user = user
      @status = status
    end

    def execute
      return error_no_permissions unless allowed?
      return error_invalid_status unless status_key

      if alert.update(status_event: status_event)
        success
      else
        error(alert.errors.full_messages.to_sentence)
      end
    end

    private

    attr_reader :alert, :user, :status

    delegate :project, to: :alert

    def allowed?
      user.can?(:update_alert_management_alert, project)
    end

    def status_key
      strong_memoize(:status_key) do
        AlertManagement::Alert::STATUSES.key(status)
      end
    end

    def status_event
      AlertManagement::Alert::STATUS_EVENTS[status_key]
    end

    def success
      ServiceResponse.success(payload: { alert: alert })
    end

    def error_no_permissions
      error(_('You have no permissions'))
    end

    def error_invalid_status
      error(_('Invalid status'))
    end

    def error(message)
      ServiceResponse.error(payload: { alert: alert }, message: message)
    end
  end
end
