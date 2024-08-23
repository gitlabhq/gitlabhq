# frozen_string_literal: true

module Gitlab
  module Tracking
    class AiTracking
      def self.track_event(*args)
        new.track_event(*args)
      end

      def track_event(_event_name, _context_hash = {})
        # no-op for CE
      end
    end
  end
end

Gitlab::Tracking::AiTracking.prepend_mod
