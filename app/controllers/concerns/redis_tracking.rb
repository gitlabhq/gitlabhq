# frozen_string_literal: true

# Example:
#
# # In controller include module
# # Track event for index action
#
# include RedisTracking
#
# track_redis_hll_event :index, :show, name: 'i_analytics_dev_ops_score'
#
# You can also pass custom conditions using `if:`, using the same format as with Rails callbacks.
# You can also pass an optional block that calculates and returns a custom id to track.
module RedisTracking
  include Gitlab::Tracking::Helpers
  extend ActiveSupport::Concern

  class_methods do
    def track_redis_hll_event(*controller_actions, name:, if: nil, &block)
      custom_conditions = Array.wrap(binding.local_variable_get('if'))
      conditions = [:trackable_html_request?, *custom_conditions]

      after_action only: controller_actions, if: conditions do
        track_unique_redis_hll_event(name, &block)
      end
    end
  end

  private

  def track_unique_redis_hll_event(event_name, &block)
    custom_id = block_given? ? yield(self) : nil

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
