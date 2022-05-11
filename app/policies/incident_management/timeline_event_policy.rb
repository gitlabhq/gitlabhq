# frozen_string_literal: true

module IncidentManagement
  class TimelineEventPolicy < ::BasePolicy
    delegate { @subject.incident }
  end
end
