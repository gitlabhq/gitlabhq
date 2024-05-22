# frozen_string_literal: true

module API
  module Helpers
    module EventsHelpers
      extend Grape::API::Helpers

      params :event_filter_params do
        optional :action, type: String, values: Event.actions, desc: 'Event action to filter on'
        optional :target_type, type: String, values: Event.target_types, desc: 'Event target type to filter on'
        optional :before, type: Date, desc: 'Include only events created before this date'
        optional :after, type: Date, desc: 'Include only events created after this date'
      end

      params :sort_params do
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
          desc: 'Return events sorted in ascending and descending order'
      end

      def present_events(events)
        events = paginate(events)

        present events, with: Entities::Event
      end

      def find_events(source)
        EventsFinder.new(params.merge(source: source, current_user: current_user, with_associations: true)).execute
      end
    end
  end
end
