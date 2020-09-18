# frozen_string_literal: true

module IncidentManagement
  module UsageData
    include Gitlab::Utils::UsageData

    def track_incident_action(current_user, target, action)
      return unless target.incident?

      track_usage_event(:"incident_management_#{action}", current_user.id)
    end

    # No-op as optionally overridden in implementing classes.
    # For use to provide checks before calling #track_incident_action.
    def track_event
    end
  end
end
