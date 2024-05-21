# frozen_string_literal: true

module Gitlab
  module Tracking
    class AiTracking
      def self.track_event(*args)
        new.track_event(*args)
      end

      def self.track_via_code_suggestions?(*args)
        new.track_via_code_suggestions?(*args)
      end

      def track_event(_event_name, _context_hash = {})
        # no-op for CE
      end

      def track_via_code_suggestions?(_event, _current_user)
        # no-op for CE
      end
    end
  end
end

Gitlab::Tracking::AiTracking.prepend_mod
