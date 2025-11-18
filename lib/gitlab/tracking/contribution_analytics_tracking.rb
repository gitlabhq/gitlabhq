# frozen_string_literal: true

module Gitlab
  module Tracking
    class ContributionAnalyticsTracking
      def self.track_event(_event_name, **kwargs)
        author = kwargs[:user]
        action = kwargs[:label]
        meta = kwargs[:meta]
        fingerprint = kwargs[:fingerprint]

        ::EventCreateService.new.wiki_event(meta, author, action.to_sym, fingerprint)
      end
    end
  end
end
