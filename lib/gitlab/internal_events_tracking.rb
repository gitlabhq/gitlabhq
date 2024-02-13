# frozen_string_literal: true

module Gitlab
  module InternalEventsTracking
    def track_internal_event(event_name, event_args)
      Gitlab::InternalEvents.track_event(event_name, category: self.class.name, **event_args)
    end
  end
end
