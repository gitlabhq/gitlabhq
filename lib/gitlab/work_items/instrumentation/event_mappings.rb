# lib/gitlab/work_items/instrumentation/event_mappings.rb
# frozen_string_literal: true

module Gitlab
  module WorkItems
    module Instrumentation
      class EventMappings
        include EventActions

        ATTRIBUTE_MAPPINGS = [
          { event: EventActions::TITLE_UPDATE, key: 'title' },
          { event: EventActions::DESCRIPTION_UPDATE, key: 'description' },
          { event: EventActions::MILESTONE_UPDATE, key: 'milestone_id' },
          { event: EventActions::WEIGHT_UPDATE, key: 'weight' },
          { event: EventActions::ITERATION_UPDATE, key: 'sprint_id' },
          { event: EventActions::HEALTH_STATUS_UPDATE, key: 'health_status' },
          { event: EventActions::START_DATE_UPDATE, key: 'start_date' },
          { event: EventActions::DUE_DATE_UPDATE, key: 'due_date' },
          { event: EventActions::TIME_ESTIMATE_UPDATE, key: 'time_estimate' },
          {
            event: ->(change) {
              _old_value, new_value = change
              new_value ? EventActions::LOCK : EventActions::UNLOCK
            },
            key: 'discussion_locked'
          }
        ].freeze

        ASSOCIATION_MAPPINGS = [
          {
            event: EventActions::ASSIGNEES_UPDATE,
            key: :assignees,
            compare: ->(old, new) { old != new }
          },
          {
            event: EventActions::CONFIDENTIALITY_ENABLE,
            key: :confidential,
            compare: ->(old_value, new_value) { old_value == false && new_value == true }
          },
          {
            event: EventActions::CONFIDENTIALITY_DISABLE,
            key: :confidential,
            compare: ->(old_value, new_value) { old_value == true && new_value == false }
          },
          {
            event: EventActions::LABELS_UPDATE,
            key: :labels,
            compare: ->(old, new) { old != new }
          },
          {
            event: EventActions::TIME_SPENT_UPDATE,
            key: :total_time_spent,
            compare: ->(old, new) { old != new }
          },
          {
            event: EventActions::MARKED_AS_DUPLICATE,
            key: :status,
            compare: ->(old, new) {
              old_name = old&.name
              new_name = new&.name
              old_name != 'Duplicate' && new_name == 'Duplicate'
            },
            accessor: ->(work_item) { work_item.current_status&.status }
          }
        ].freeze

        def self.events_for(work_item:, old_associations:)
          new(work_item, old_associations).events_to_track
        end

        def initialize(work_item, old_associations)
          @work_item = work_item
          @old_associations = old_associations
        end

        def events_to_track
          events = []

          ATTRIBUTE_MAPPINGS.each do |mapping|
            change = @work_item.previous_changes[mapping[:key]]
            next unless change

            event = mapping[:event]
            if event.respond_to?(:call)
              event_name = event.call(change)
              events << event_name if event_name
            else
              events << event
            end
          end

          ASSOCIATION_MAPPINGS.each do |mapping|
            next unless @old_associations.key?(mapping[:key])

            old_value = @old_associations[mapping[:key]]
            # rubocop:disable GitlabSecurity/PublicSend -- model attribute, not user input
            new_value = if mapping[:accessor]
                          mapping[:accessor].call(@work_item)
                        else
                          @work_item.public_send(mapping[:key])
                        end
            # rubocop:enable GitlabSecurity/PublicSend

            events << mapping[:event] if mapping[:compare].call(old_value, new_value)
          end

          events
        end
      end
    end
  end
end
