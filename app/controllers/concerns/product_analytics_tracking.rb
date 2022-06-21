# frozen_string_literal: true

module ProductAnalyticsTracking
  include Gitlab::Tracking::Helpers
  include RedisTracking
  extend ActiveSupport::Concern

  class_methods do
    def track_event(*controller_actions, name:, conditions: nil, destinations: [:redis_hll], &block)
      custom_conditions = [:trackable_html_request?, *conditions]

      after_action only: controller_actions, if: custom_conditions do
        route_events_to(destinations, name, &block)
      end
    end
  end

  private

  def route_events_to(destinations, name, &block)
    track_unique_redis_hll_event(name, &block) if destinations.include?(:redis_hll)

    if destinations.include?(:snowplow) && event_enabled?(name)
      Gitlab::Tracking.event(self.class.to_s, name, namespace: tracking_namespace_source, user: current_user)
    end
  end

  def event_enabled?(event)
    events_to_ff = {
      g_analytics_valuestream: :route_hll_to_snowplow,

      i_search_paid: :route_hll_to_snowplow_phase2,
      i_search_total: :route_hll_to_snowplow_phase2,
      i_search_advanced: :route_hll_to_snowplow_phase2
    }

    Feature.enabled?(events_to_ff[event.to_sym], tracking_namespace_source)
  end
end
