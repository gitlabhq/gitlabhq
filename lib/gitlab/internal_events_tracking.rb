# frozen_string_literal: true

module Gitlab
  module InternalEventsTracking
    GENERIC_CATEGORIES = ['Grape::Endpoint'].freeze

    def track_internal_event(event_name, event_args)
      category = is_a?(Class) ? name : self.class.name
      category = nil if GENERIC_CATEGORIES.include?(category)
      Gitlab::InternalEvents.track_event(event_name, category: category, **event_args)
    end
  end
end
