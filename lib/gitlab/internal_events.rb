# frozen_string_literal: true

module Gitlab
  module InternalEvents
    UnknownEventError = Class.new(StandardError)
    MissingPropertyError = Class.new(StandardError)

    class << self
      include Gitlab::Tracking::Helpers

      def track_event(event_name, **kwargs)
        raise UnknownEventError, "Unknown event: #{event_name}" unless EventDefinitions.known_event?(event_name)

        unique_key = EventDefinitions.unique_property(event_name)

        unless kwargs.has_key?(unique_key)
          raise MissingPropertyError, "#{event_name} should be triggered with a '#{unique_key}' property"
        end

        UsageDataCounters::HLLRedisCounter.track_event(event_name, values: kwargs[unique_key])

        user_id = kwargs[:user_id]
        project_id = kwargs[:project_id]
        namespace_id = kwargs[:namespace_id]

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
      rescue StandardError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, event_name: event_name, kwargs: kwargs)
        nil
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
