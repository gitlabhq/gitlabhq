# frozen_string_literal: true

module ProductAnalyticsTracking
  include Gitlab::Tracking::Helpers
  include RedisTracking
  extend ActiveSupport::Concern

  class_methods do
    def track_event(*controller_actions, name:, action: nil, label: nil, conditions: nil, destinations: [:redis_hll], &block)
      custom_conditions = [:trackable_html_request?, *conditions]

      after_action only: controller_actions, if: custom_conditions do
        route_events_to(destinations, name, action, label, &block)
      end
    end
  end

  private

  def route_events_to(destinations, name, action, label, &block)
    track_unique_redis_hll_event(name, &block) if destinations.include?(:redis_hll)

    return unless destinations.include?(:snowplow)
    raise "action is required when destination is snowplow" unless action
    raise "label is required when destination is snowplow" unless label

    optional_arguments = {
      namespace: tracking_namespace_source,
      project: tracking_project_source
    }.compact

    Gitlab::Tracking.event(
      self.class.to_s,
      action,
      user: current_user,
      property: name,
      label: label,
      context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: name).to_context],
      **optional_arguments
    )
  end
end
