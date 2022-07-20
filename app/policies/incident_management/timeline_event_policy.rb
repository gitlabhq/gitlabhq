# frozen_string_literal: true

module IncidentManagement
  class TimelineEventPolicy < ::BasePolicy
    delegate { @subject.incident }

    condition(:is_editable, scope: :subject, score: 0) { @subject.editable? }

    rule { ~can?(:admin_incident_management_timeline_event) }.policy do
      prevent :edit_incident_management_timeline_event
    end

    rule { is_editable }.policy do
      enable :edit_incident_management_timeline_event
    end
  end
end
