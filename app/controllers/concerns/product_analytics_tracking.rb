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

    def track_custom_event(*controller_actions, name:, conditions: nil, action:, label:, destinations: [:redis_hll], &block)
      custom_conditions = [:trackable_html_request?, *conditions]

      after_action only: controller_actions, if: custom_conditions do
        route_custom_events_to(destinations, name, action, label, &block)
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

  def route_custom_events_to(destinations, name, action, label, &block)
    track_unique_redis_hll_event(name, &block) if destinations.include?(:redis_hll)

    return unless destinations.include?(:snowplow) && event_enabled?(name)

    optional_arguments = {
      project: tracking_project_source
    }.compact

    Gitlab::Tracking.event(
      self.class.to_s,
      action,
      user: current_user,
      property: name,
      label: label,
      namespace: tracking_namespace_source,
      **optional_arguments
    )
  end

  def event_enabled?(event)
    events_to_ff = {
      g_analytics_valuestream: :route_hll_to_snowplow,

      i_search_paid: :route_hll_to_snowplow_phase2,
      i_search_total: :route_hll_to_snowplow_phase2,
      i_search_advanced: :route_hll_to_snowplow_phase2,
      i_ecosystem_jira_service_list_issues: :route_hll_to_snowplow_phase2
    }

    Feature.enabled?(events_to_ff[event.to_sym], tracking_namespace_source)
  end
end
