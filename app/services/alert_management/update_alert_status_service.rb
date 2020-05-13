# frozen_string_literal: true

module AlertManagement
  class UpdateAlertStatusService
    include Gitlab::Utils::StrongMemoize

    # @param alert [AlertManagement::Alert]
    # @param status [Integer] Must match a value from AlertManagement::Alert::STATUSES
    def initialize(alert, status)
      @alert = alert
      @status = status
    end

    def execute
      return error('Invalid status') unless status_key

      if alert.update(status_event: status_event)
        success
      else
        error(alert.errors.full_messages.to_sentence)
      end
    end

    private

    attr_reader :alert, :status

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

    def error(message)
      ServiceResponse.error(payload: { alert: alert }, message: message)
    end
  end
end
