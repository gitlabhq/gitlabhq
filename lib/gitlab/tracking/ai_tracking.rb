# frozen_string_literal: true

module Gitlab
  module Tracking
    class AiTracking
      def self.track_event(*args, **kwargs)
        new.track_event(*args, **kwargs)
      end

      def self.track_user_activity(*args)
        new.track_user_activity(*args)
      end

      def track_event(_event_name, **_context_hash)
        # no-op for CE
      end

      def track_user_activity(_user)
        # no-op for CE
      end
    end
  end
end

Gitlab::Tracking::AiTracking.prepend_mod
