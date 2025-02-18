# frozen_string_literal: true

module Gitlab
  module InternalEvents
    SNOWPLOW_EMITTER_BUFFER_SIZE = 100
    DEFAULT_BUFFER_SIZE = 1
    KEY_EXPIRY_LENGTH = Gitlab::UsageDataCounters::HLLRedisCounter::KEY_EXPIRY_LENGTH

    class << self
      include Gitlab::Tracking::Helpers
      include Gitlab::Utils::StrongMemoize
      include Gitlab::UsageDataCounters::RedisCounter
      include Gitlab::UsageDataCounters::RedisSum

      def track_event(event_name, category: nil, additional_properties: {}, **kwargs)
        unless Gitlab::Tracking::EventDefinition.internal_event_exists?(event_name)
          Gitlab::AppJsonLogger.warn("InternalEvents.track_event called with undefined event: #{event_name}")
        end

        Gitlab::Tracking::EventValidator.new(event_name, additional_properties, kwargs).validate!

        event_definition = Gitlab::Tracking::EventDefinition.find(event_name)
        send_snowplow_event = kwargs.fetch(:send_snowplow_event, true)

        track_analytics_event(event_name, send_snowplow_event, category: category,
          additional_properties: additional_properties, **kwargs)

        kwargs[:additional_properties] = additional_properties
        event_definition.extra_tracking_classes.each do |tracking_class|
          tracking_class.track_event(event_name, **kwargs)
        end

      rescue StandardError => e
        extra = {}
        kwargs.each_key do |k|
          extra[k] = kwargs[k].is_a?(::ApplicationRecord) ? kwargs[k].try(:id) : kwargs[k]
        end

        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
          e,
          event_name: event_name,
          additional_properties: additional_properties,
          kwargs: extra
        )
        nil
      end

      private

      def track_analytics_event(event_name, send_snowplow_event, category: nil, additional_properties: {}, **kwargs)
        extra = custom_additional_properties(additional_properties)
        base_additional_properties = additional_properties.slice(*base_additional_properties_keys)

        project = kwargs[:project]
        kwargs[:namespace] ||= project.namespace if project

        update_redis_values(event_name, additional_properties, kwargs)
        trigger_snowplow_event(event_name, category, base_additional_properties, extra, kwargs) if send_snowplow_event
        send_application_instrumentation_event(event_name, base_additional_properties, kwargs) if send_snowplow_event

        return unless Feature.enabled?(:early_access_program, kwargs[:user], type: :wip)

        create_early_access_program_event(event_name, category, additional_properties[:label], kwargs)
      end

      def update_redis_values(event_name, additional_properties, kwargs)
        event_definition = Gitlab::Tracking::EventDefinition.find(event_name)

        return unless event_definition

        event_definition.event_selection_rules.each do |event_selection_rule|
          matches_filter = event_selection_rule.matches?(additional_properties)

          next unless matches_filter

          if event_selection_rule.total_counter?
            update_total_counter(event_selection_rule)
          elsif event_selection_rule.sum?
            update_sums(event_selection_rule, **kwargs, **additional_properties)
          else
            update_unique_counter(event_selection_rule, **kwargs, **additional_properties)
          end
        end
      end

      def custom_additional_properties(additional_properties)
        additional_properties.except(*base_additional_properties_keys)
      end

      def update_total_counter(event_selection_rule)
        expiry = event_selection_rule.time_framed? ? KEY_EXPIRY_LENGTH : nil

        # Overrides for legacy keys of total counters are handled in `increment`
        increment(event_selection_rule.redis_key_for_date, expiry: expiry)
      end

      def update_sums(event_selection_rule, properties)
        # Hardcoded to only look at 'value' since that all the schema allows.
        # Should be dynamic based on the event selection rule
        return unless properties.has_key?(:value)

        expiry = event_selection_rule.time_framed? ? KEY_EXPIRY_LENGTH : nil

        increment_sum_by(event_selection_rule.redis_key_for_date, properties[:value], expiry: expiry)
      end

      def update_unique_counter(event_selection_rule, properties)
        identifier_name = event_selection_rule.unique_identifier_name

        unless properties[identifier_name]
          message = "#{event_selection_rule.name} should be triggered with a named parameter '#{identifier_name}'."
          Gitlab::AppJsonLogger.warn(message: message)
          return
        end

        # Use id for ActiveRecord objects, else normalize size of stored value
        unique_value = properties[identifier_name].try(:id) || properties[identifier_name].hash

        # Overrides for legacy keys of unique counters are handled in `event_selection_rule.redis_key_for_date`
        Gitlab::Redis::HLL.add(
          key: event_selection_rule.redis_key_for_date,
          value: unique_value,
          expiry: KEY_EXPIRY_LENGTH
        )
      end

      def trigger_snowplow_event(event_name, category, additional_properties, extra, kwargs)
        user = kwargs[:user]
        project = kwargs[:project]
        namespace = kwargs[:namespace]
        feature_enabled_by_namespace_ids = kwargs[:feature_enabled_by_namespace_ids]

        standard_context = Tracking::StandardContext.new(
          project_id: project&.id,
          user: user,
          namespace_id: namespace&.id,
          plan_name: namespace&.actual_plan_name,
          feature_enabled_by_namespace_ids: feature_enabled_by_namespace_ids,
          **extra
        ).to_context

        service_ping_context = Tracking::ServicePingContext.new(
          data_source: :redis_hll,
          event: event_name
        ).to_context

        contexts = [standard_context, service_ping_context]
        track_struct_event(event_name, category, contexts: contexts, additional_properties: additional_properties)
      end

      def track_struct_event(event_name, category, contexts:, additional_properties:)
        category ||= 'InternalEventTracking'
        tracker = Gitlab::Tracking.tracker
        tracker.event(category, event_name, context: contexts, **additional_properties)
      rescue StandardError => error
        Gitlab::ErrorTracking
          .track_and_raise_for_dev_exception(error, snowplow_category: category, snowplow_action: event_name)
      end

      def send_application_instrumentation_event(event_name, additional_properties, kwargs)
        return if gitlab_sdk_client.nil?

        user = kwargs[:user]

        gitlab_sdk_client.identify(user&.id)

        tracked_attributes = { project_id: kwargs[:project]&.id, namespace_id: kwargs[:namespace]&.id }
        tracked_attributes[:additional_properties] = additional_properties unless additional_properties.empty?
        gitlab_sdk_client.track(event_name, tracked_attributes)
      end

      def create_early_access_program_event(event_name, category, event_label, kwargs)
        user, namespace = kwargs.values_at(:user, :namespace)
        return if user.nil? || !namespace&.namespace_settings&.early_access_program_participant?

        ::EarlyAccessProgram::TrackingEvent.create(
          user: user, event_name: event_name.to_s, event_label: event_label, category: category
        )
      end

      def gitlab_sdk_client
        app_id = ENV['GITLAB_ANALYTICS_ID']
        host = ENV['GITLAB_ANALYTICS_URL']

        return unless app_id.present? && host.present?

        buffer_size = Feature.enabled?(:internal_events_batching) ? SNOWPLOW_EMITTER_BUFFER_SIZE : DEFAULT_BUFFER_SIZE
        GitlabSDK::Client.new(app_id: app_id, host: host, buffer_size: buffer_size)
      end
      strong_memoize_attr :gitlab_sdk_client

      def base_additional_properties_keys
        Gitlab::Tracking::EventValidator::BASE_ADDITIONAL_PROPERTIES.keys
      end
    end
  end
end
