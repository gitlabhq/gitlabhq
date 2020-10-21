# frozen_string_literal: true

# Example:
#
# # In controller include module
# # Track event for index action
#
# include RedisTracking
#
# track_redis_hll_event :index, :show, name: 'i_analytics_dev_ops_score', feature: :my_feature
#
# if the feature flag is enabled by default you should use
# track_redis_hll_event :index, :show, name: 'i_analytics_dev_ops_score', feature: :my_feature, feature_default_enabled: true
#
# You can also pass custom conditions using `if:`, using the same format as with Rails callbacks.
module RedisTracking
  extend ActiveSupport::Concern

  class_methods do
    def track_redis_hll_event(*controller_actions, name:, feature:, feature_default_enabled: false, if: nil)
      custom_conditions = Array.wrap(binding.local_variable_get('if'))
      conditions = [:trackable_request?, *custom_conditions]

      after_action only: controller_actions, if: conditions do
        track_unique_redis_hll_event(name, feature, feature_default_enabled)
      end
    end
  end

  private

  def track_unique_redis_hll_event(event_name, feature, feature_default_enabled)
    return unless metric_feature_enabled?(feature, feature_default_enabled)
    return unless visitor_id

    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(visitor_id, event_name)
  end

  def trackable_request?
    request.format.html? && request.headers['DNT'] != '1'
  end

  def metric_feature_enabled?(feature, default_enabled)
    Feature.enabled?(feature, default_enabled: default_enabled)
  end

  def visitor_id
    return cookies[:visitor_id] if cookies[:visitor_id].present?
    return unless current_user

    uuid = SecureRandom.uuid
    cookies[:visitor_id] = { value: uuid, expires: 24.months }
    uuid
  end
end
