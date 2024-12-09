# frozen_string_literal: true

module Gitlab
  module Tracking
    class AiTracking
      # events getting taken care of by instrumentation layer
      EVENTS_MIGRATED_TO_INSTRUMENTATION_LAYER = ['request_duo_chat_response'].freeze

      def self.track_event(*args, **kwargs)
        new.track_event(*args, **kwargs)
      end

      def track_event(_event_name, **_context_hash)
        # no-op for CE
      end
    end
  end
end

Gitlab::Tracking::AiTracking.prepend_mod
