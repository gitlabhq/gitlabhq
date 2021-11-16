# frozen_string_literal: true

module ResourceEvents
  class SyntheticStateNotesBuilderService < BaseSyntheticNotesBuilderService
    private

    def synthetic_notes
      state_change_events.map do |event|
        StateNote.from_event(event, resource: resource, resource_parent: resource_parent)
      end
    end

    def state_change_events
      return [] unless resource.respond_to?(:resource_state_events)

      events = resource.resource_state_events.includes(user: :status) # rubocop: disable CodeReuse/ActiveRecord
      apply_common_filters(events)
    end

    def table_name
      'resource_state_events'
    end
  end
end
