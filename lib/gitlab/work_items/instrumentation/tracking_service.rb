# frozen_string_literal: true

module Gitlab
  module WorkItems
    module Instrumentation
      class TrackingService
        include Gitlab::InternalEventsTracking
        include EventActions

        def initialize(work_item:, current_user:, event: nil, old_associations: nil)
          raise ArgumentError unless valid_params?(work_item, current_user, event, old_associations)

          @work_item = work_item
          @current_user = current_user
          @event = event
          @old_associations = old_associations
        end

        def execute
          if @event
            track_internal_event(@event, **event_properties)
          else
            EventMappings
              .events_for(work_item: @work_item, old_associations: @old_associations)
              .each { |event_name| track_internal_event(event_name, **event_properties) }
          end
        end

        private

        def event_properties
          {
            user: @current_user,
            namespace: @work_item.project&.project_namespace || @work_item.namespace,
            project: @work_item.project,
            additional_properties: {
              label: @work_item.work_item_type.name,
              property: @work_item.namespace.user_role(@current_user)
            }
          }
        end

        def valid_params?(work_item, current_user, event, old_associations)
          return false unless work_item.is_a?(Issue)
          return false unless current_user.is_a?(User)
          return false if event && !EventActions.valid_event?(event)
          return false if event && old_associations
          return false if !event && !old_associations

          true
        end
      end
    end
  end
end
