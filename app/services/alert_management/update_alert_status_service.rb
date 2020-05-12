# frozen_string_literal: true

module AlertManagement
  class UpdateAlertStatusService
    def initialize(alert, status)
      @alert = alert
      @status = status
    end

    def execute
      return error('Invalid status') unless AlertManagement::Alert::STATUSES.key?(status.to_sym)

      alert.status_event = AlertManagement::Alert::STATUS_EVENTS[status.to_sym]

      if alert.save
        success
      else
        error(alert.errors.full_messages.to_sentence)
      end
    end

    private

    attr_reader :alert, :status

    def success
      ServiceResponse.success(payload: { alert: alert })
    end

    def error(message)
      ServiceResponse.error(payload: { alert: alert }, message: message)
    end
  end
end
