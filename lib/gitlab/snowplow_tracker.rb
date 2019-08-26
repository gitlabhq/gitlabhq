# frozen_string_literal: true

require 'snowplow-tracker'

module Gitlab
  module SnowplowTracker
    NAMESPACE = 'cf'

    class << self
      def track_event(category, action, label: nil, property: nil, value: nil, context: nil)
        tracker&.track_struct_event(category, action, label, property, value, context, Time.now.to_i)
      end

      private

      def tracker
        return unless enabled?

        @tracker ||= ::SnowplowTracker::Tracker.new(emitter, subject, NAMESPACE, Gitlab::CurrentSettings.snowplow_site_id)
      end

      def subject
        ::SnowplowTracker::Subject.new
      end

      def emitter
        ::SnowplowTracker::Emitter.new(Gitlab::CurrentSettings.snowplow_collector_hostname)
      end

      def enabled?
        Gitlab::CurrentSettings.snowplow_enabled?
      end
    end
  end
end
