# frozen_string_literal: true

module Gitlab
  module InternalEvents
    UnknownEventError = Class.new(StandardError)
    InvalidPropertyError = Class.new(StandardError)
    InvalidMethodError = Class.new(StandardError)

    class << self
      include Gitlab::Tracking::Helpers

      def track_event(event_name, send_snowplow_event: true, **kwargs)
        raise UnknownEventError, "Unknown event: #{event_name}" unless EventDefinitions.known_event?(event_name)

        increase_total_counter(event_name)
        update_unique_counter(event_name, kwargs)
        trigger_snowplow_event(event_name, kwargs) if send_snowplow_event
      rescue StandardError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, event_name: event_name, kwargs: kwargs)
        nil
      end

      private

      def increase_total_counter(event_name)
        return unless ::ServicePing::ServicePingSettings.enabled?

        redis_counter_key =
          Gitlab::Usage::Metrics::Instrumentations::TotalCountMetric.redis_key(event_name)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      def update_unique_counter(event_name, kwargs)
        unique_property = EventDefinitions.unique_property(event_name)
        return unless unique_property

        unique_method = :id

        unless kwargs.has_key?(unique_property)
          raise InvalidPropertyError, "#{event_name} should be triggered with a named parameter '#{unique_property}'."
        end

        unless kwargs[unique_property].respond_to?(unique_method)
          raise InvalidMethodError, "'#{unique_property}' should have a '#{unique_method}' method."
        end

        unique_value = kwargs[unique_property].public_send(unique_method) # rubocop:disable GitlabSecurity/PublicSend

        UsageDataCounters::HLLRedisCounter.track_event(event_name, values: unique_value)
      end

      def trigger_snowplow_event(event_name, kwargs)
        user = kwargs[:user]
        project = kwargs[:project]
        namespace = kwargs[:namespace]

        standard_context = Tracking::StandardContext.new(
          project_id: project&.id,
          user_id: user&.id,
          namespace_id: namespace&.id,
          plan_name: namespace&.actual_plan_name
        ).to_context

        service_ping_context = Tracking::ServicePingContext.new(
          data_source: :redis_hll,
          event: event_name
        ).to_context

        track_struct_event(event_name, contexts: [standard_context, service_ping_context])
      end

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
