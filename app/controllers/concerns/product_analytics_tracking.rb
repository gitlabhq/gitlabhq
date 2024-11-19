# frozen_string_literal: true

module ProductAnalyticsTracking
  include Gitlab::Tracking::Helpers
  extend ActiveSupport::Concern

  class_methods do
    def track_event(
      *controller_actions, name:, action: nil, label: nil, conditions: nil, destinations: [:redis_hll],
      &block)
      custom_conditions = [:trackable_html_request?, *conditions]

      after_action only: controller_actions, if: custom_conditions do
        route_events_to(destinations, name, action, label, &block)
      end
    end

    def track_internal_event(*controller_actions, name:, conditions: nil, **event_args)
      custom_conditions = [:trackable_html_request?, *conditions]

      after_action only: controller_actions, if: custom_conditions do
        Gitlab::InternalEvents.track_event(
          name,
          user: current_user,
          project: tracking_project_source,
          namespace: tracking_namespace_source,
          **event_args.compact
        )
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

  def track_unique_redis_hll_event(event_name, &block)
    custom_id = block ? yield(self) : nil

    unique_id = custom_id || visitor_id

    return unless unique_id

    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event_name, values: unique_id)
  end

  def visitor_id
    return cookies[:visitor_id] if cookies[:visitor_id].present?
    return unless current_user

    uuid = SecureRandom.uuid
    cookies[:visitor_id] = { value: uuid, expires: 24.months }
    uuid
  end
end
