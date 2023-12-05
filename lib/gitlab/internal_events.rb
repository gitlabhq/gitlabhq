# frozen_string_literal: true

module Gitlab
  module InternalEvents
    UnknownEventError = Class.new(StandardError)
    InvalidPropertyError = Class.new(StandardError)
    InvalidPropertyTypeError = Class.new(StandardError)

    class << self
      include Gitlab::Tracking::Helpers
      include Gitlab::Utils::StrongMemoize

      def track_event(event_name, send_snowplow_event: true, **kwargs)
        raise UnknownEventError, "Unknown event: #{event_name}" unless EventDefinitions.known_event?(event_name)

        validate_property!(kwargs, :user, User)
        validate_property!(kwargs, :namespace, Namespaces::UserNamespace, Group)
        validate_property!(kwargs, :project, Project)

        project = kwargs[:project]
        kwargs[:namespace] ||= project.namespace if project

        increase_total_counter(event_name)
        increase_weekly_total_counter(event_name)
        update_unique_counter(event_name, kwargs)
        trigger_snowplow_event(event_name, kwargs) if send_snowplow_event

        if Feature.enabled?(:internal_events_for_product_analytics)
          send_application_instrumentation_event(event_name, kwargs)
        end
      rescue StandardError => e
        extra = {}
        kwargs.each_key do |k|
          extra[k] = kwargs[k].is_a?(::ApplicationRecord) ? kwargs[k].try(:id) : kwargs[k]
        end
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, event_name: event_name, kwargs: extra)
        nil
      end

      private

      def validate_property!(kwargs, property_name, *class_names)
        return unless kwargs.has_key?(property_name)
        return if kwargs[property_name].nil?
        return if class_names.include?(kwargs[property_name].class)

        raise InvalidPropertyTypeError, "#{property_name} should be an instance of #{class_names.join(', ')}"
      end

      def increase_total_counter(event_name)
        redis_counter_key =
          Gitlab::Usage::Metrics::Instrumentations::TotalCountMetric.redis_key(event_name)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      def increase_weekly_total_counter(event_name)
        redis_counter_key =
          Gitlab::Usage::Metrics::Instrumentations::TotalCountMetric.redis_key(event_name, Date.today)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      def update_unique_counter(event_name, kwargs)
        unique_property = EventDefinitions.unique_property(event_name)
        return unless unique_property

        unique_method = :id

        unless kwargs.has_key?(unique_property)
          message = "#{event_name} should be triggered with a named parameter '#{unique_property}'."
          Gitlab::AppJsonLogger.warn(message: message)
          return
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

      def send_application_instrumentation_event(event_name, kwargs)
        return if gitlab_sdk_client.nil?

        user = kwargs[:user]

        gitlab_sdk_client.identify(user&.id)
        gitlab_sdk_client.track(event_name, nil)
      end

      def gitlab_sdk_client
        app_id = ENV['GITLAB_ANALYTICS_ID']
        host = ENV['GITLAB_ANALYTICS_URL']

        return unless app_id.present? && host.present?

        GitlabSDK::Client.new(app_id: app_id, host: host)
      end
      strong_memoize_attr :gitlab_sdk_client
    end
  end
end
