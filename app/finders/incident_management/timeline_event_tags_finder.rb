# frozen_string_literal: true

module IncidentManagement
  class TimelineEventTagsFinder
    def initialize(user, timeline_event, params = {})
      @user = user
      @timeline_event = timeline_event
      @params = params
    end

    def execute
      return ::IncidentManagement::TimelineEventTag.none unless allowed?

      timeline_event.timeline_event_tags
    end

    private

    attr_reader :user, :timeline_event, :params

    def allowed?
      Ability.allowed?(user, :read_incident_management_timeline_event_tag, timeline_event)
    end
  end
end
