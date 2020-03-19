# frozen_string_literal: true

# We store events about resource milestone changes in a separate table,
# but we still want to display notes about milestone changes
# as classic system notes in UI. This service generates "synthetic" notes for
# milestone event changes.

module ResourceEvents
  class SyntheticMilestoneNotesBuilderService < BaseSyntheticNotesBuilderService
    private

    def synthetic_notes
      return [] unless tracking_enabled?

      milestone_change_events.map do |event|
        MilestoneNote.from_event(event, resource: resource, resource_parent: resource_parent)
      end
    end

    def milestone_change_events
      return [] unless resource.respond_to?(:resource_milestone_events)

      events = resource.resource_milestone_events.includes(user: :status) # rubocop: disable CodeReuse/ActiveRecord
      since_fetch_at(events)
    end

    def tracking_enabled?
      ::Feature.enabled?(:track_resource_milestone_change_events, resource.project)
    end
  end
end
