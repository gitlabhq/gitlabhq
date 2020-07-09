# frozen_string_literal: true

module SystemNotes
  class AlertManagementService < ::SystemNotes::BaseService
    # Called when the status of an AlertManagement::Alert has changed
    #
    # alert - AlertManagement::Alert object.
    #
    # Example Note text:
    #
    #   "changed the status to Acknowledged"
    #
    # Returns the created Note object
    def change_alert_status(alert)
      status = AlertManagement::Alert::STATUSES.key(alert.status).to_s.titleize
      body = "changed the status to **#{status}**"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'status'))
    end
  end
end
