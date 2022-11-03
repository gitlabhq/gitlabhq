# frozen_string_literal: true

module IncidentManagement
  class TimelineEventTagPolicy < ::BasePolicy
    delegate { @subject.project }
  end
end
