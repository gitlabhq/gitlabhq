# frozen_string_literal: true

module Gitlab
  module InternalEventsTracking
    def track_internal_event(event_name, event_args)
      category = is_a?(Class) ? name : self.class.name
      Gitlab::InternalEvents.track_event(event_name, category: category, **event_args)
    end
  end
end
