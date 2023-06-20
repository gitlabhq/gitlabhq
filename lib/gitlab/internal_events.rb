# frozen_string_literal: true

module Gitlab
  module InternalEvents
    class << self
      include Gitlab::Tracking::Helpers

      def track_event(event_name, **kwargs)
        user_id = kwargs.delete(:user_id)
        UsageDataCounters::HLLRedisCounter.track_event(event_name, values: user_id)

        project_id = kwargs.delete(:project_id)
        namespace_id = kwargs.delete(:namespace_id)

        namespace = Namespace.find(namespace_id) if namespace_id

        standard_context = Tracking::StandardContext.new(
          project_id: project_id,
          user_id: user_id,
          namespace_id: namespace&.id,
          plan_name: namespace&.actual_plan_name
        ).to_context

        service_ping_context = Tracking::ServicePingContext.new(
          data_source: :redis_hll,
          event: event_name
        ).to_context

        track_struct_event(event_name, contexts: [standard_context, service_ping_context])
      end

      private

      def track_struct_event(event_name, contexts:)
        category = 'InternalEventTracking'
        tracker = Gitlab::Tracking.tracker
        tracker.event(category, event_name, context: contexts)
      rescue StandardError => error
        Gitlab::ErrorTracking
          .track_and_raise_for_dev_exception(error, snowplow_category: category, snowplow_action: event_name)
      end
    end
  end
end
