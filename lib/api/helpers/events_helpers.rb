# frozen_string_literal: true

module API
  module Helpers
    module EventsHelpers
      extend Grape::API::Helpers

      params :event_filter_params do
        optional :action, type: String, desc: 'Filter events by the specified [action type](https://docs.gitlab.com/user/profile/contributions_calendar/#user-contribution-events).'
        optional :target_type, type: String, values: Event.target_types, desc: 'Filter events by target type.'
        optional :before, type: Date, desc: 'Return events created before the specified date.'
        optional :after, type: Date, desc: 'Return events created after the specified date.'
      end

      params :sort_params do
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
          desc: 'Sort results in ascending or descending order by creation date.'
      end

      def present_events(events)
        events = paginate(events)

        present events, with: Entities::Event
      end

      def find_events(source)
        EventsFinder.new(
          params.merge(
            source: source,
            current_user: current_user,
            with_associations: true,
            organization: ::Current.organization
          )
        ).execute
      end
    end
  end
end
