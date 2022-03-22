# frozen_string_literal: true

module IncidentManagement
  module UsageData
    include Gitlab::Utils::UsageData

    def track_incident_action(current_user, target, action)
      return unless target.incident?

      track_usage_event(:"incident_management_#{action}", current_user.id)
    end
  end
end
