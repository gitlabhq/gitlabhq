# frozen_string_literal: true

module IncidentManagement
  class TimelineEventsFinder
    def initialize(user, incident, params = {})
      @user = user
      @incident = incident
      @params = params
    end

    def execute
      return ::IncidentManagement::TimelineEvent.none unless allowed?

      collection = incident.incident_management_timeline_events
      collection = by_id(collection)
      sort(collection)
    end

    private

    attr_reader :user, :incident, :params

    def allowed?
      Ability.allowed?(user, :read_incident_management_timeline_event, incident)
    end

    def by_id(collection)
      return collection unless params[:id]

      collection.id_in(params[:id])
    end

    def sort(collection)
      collection.order_occurred_at_asc_id_asc
    end
  end
end
