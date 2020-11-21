# frozen_string_literal: true

module Gitlab
  module Tracking
    module Destinations
      class ProductAnalytics < Base
        extend ::Gitlab::Utils::Override
        include ::Gitlab::Utils::StrongMemoize

        override :event
        def event(category, action, label: nil, property: nil, value: nil, context: nil)
          return unless event_allowed?(category, action)
          return unless enabled?

          tracker.track_struct_event(category, action, label, property, value, context, (Time.now.to_f * 1000).to_i)
        end

        private

        def event_allowed?(category, action)
          category == 'epics' && action == 'promote'
        end

        def enabled?
          Feature.enabled?(:product_analytics_tracking, type: :ops) &&
            Gitlab::CurrentSettings.usage_ping_enabled? &&
            Gitlab::CurrentSettings.self_monitoring_project_id.present?
        end

        def tracker
          @tracker ||= SnowplowTracker::Tracker.new(
            SnowplowTracker::AsyncEmitter.new(::ProductAnalytics::Tracker::COLLECTOR_URL, protocol: Gitlab.config.gitlab.protocol),
            SnowplowTracker::Subject.new,
            Gitlab::Tracking::SNOWPLOW_NAMESPACE,
            Gitlab::CurrentSettings.self_monitoring_project_id.to_s
          )
        end
      end
    end
  end
end
