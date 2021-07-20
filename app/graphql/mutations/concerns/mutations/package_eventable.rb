# frozen_string_literal: true

module Mutations
  module PackageEventable
    extend ActiveSupport::Concern

    private

    def track_event(event, scope)
      ::Packages::CreateEventService.new(nil, current_user, event_name: event, scope: scope).execute
      ::Gitlab::Tracking.event(event.to_s, scope.to_s, user: current_user)
    end
  end
end
