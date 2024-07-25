# frozen_string_literal: true

module Gitlab
  module InternalEvents
    UnknownEventError = Class.new(StandardError)
    InvalidPropertyError = Class.new(StandardError)
    InvalidPropertyTypeError = Class.new(StandardError)

    SNOWPLOW_EMITTER_BUFFER_SIZE = 100
    DEFAULT_BUFFER_SIZE = 1
    BASE_ADDITIONAL_PROPERTIES = {
      label: [String],
      property: [String],
      value: [Integer, Float]
    }.freeze
    KEY_EXPIRY_LENGTH = Gitlab::UsageDataCounters::HLLRedisCounter::KEY_EXPIRY_LENGTH

    class << self
      include Gitlab::Tracking::Helpers
      include Gitlab::Utils::StrongMemoize
      include Gitlab::UsageDataCounters::RedisCounter

      def track_event(
        event_name, category: nil, send_snowplow_event: true,
        additional_properties: {}, **kwargs)

        extra = custom_additional_properties(additional_properties)
        additional_properties = additional_properties.slice(*BASE_ADDITIONAL_PROPERTIES.keys)

        unless Gitlab::Tracking::EventDefinition.internal_event_exists?(event_name)
          raise UnknownEventError, "Unknown event: #{event_name}"
        end

        validate_properties!(additional_properties, kwargs)

        project = kwargs[:project]
        kwargs[:namespace] ||= project.namespace if project

        update_redis_values(event_name, additional_properties, kwargs)
        trigger_snowplow_event(event_name, category, additional_properties, extra, kwargs) if send_snowplow_event
        send_application_instrumentation_event(event_name, additional_properties, kwargs) if send_snowplow_event

        if Feature.enabled?(:early_access_program, kwargs[:user], type: :wip)
          create_early_access_program_event(event_name, category, additional_properties[:label], kwargs)
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

      def validate_properties!(additional_properties, kwargs)
        validate_property!(kwargs, :user, User)
        validate_property!(kwargs, :namespace, Namespaces::UserNamespace, Group)
        validate_property!(kwargs, :project, Project)
        validate_additional_properties!(additional_properties)
      end

      def validate_property!(hash, key, *class_names)
        return unless hash.has_key?(key)
        return if hash[key].nil?
        return if class_names.include?(hash[key].class)

        raise InvalidPropertyTypeError, "#{key} should be an instance of #{class_names.join(', ')}"
      end

      def validate_additional_properties!(additional_properties)
        BASE_ADDITIONAL_PROPERTIES.keys.intersection(additional_properties.keys).each do |key|
          allowed_classes = BASE_ADDITIONAL_PROPERTIES[key]
          validate_property!(additional_properties, key, *allowed_classes)
        end
      end

      def update_redis_values(event_name, additional_properties, kwargs)
        event_definition = Gitlab::Tracking::EventDefinition.find(event_name)

        return unless event_definition

        event_definition.event_selection_rules.each do |event_selection_rule|
          matches_filter = event_selection_rule.matches?(additional_properties)

          next unless matches_filter

          if event_selection_rule.total_counter?
            update_total_counter(event_selection_rule)
          else
            update_unique_counter(event_selection_rule, kwargs)
          end
        end
      end

      def custom_additional_properties(additional_properties)
        additional_properties.except(*BASE_ADDITIONAL_PROPERTIES.keys)
      end

      def update_total_counter(event_selection_rule)
        expiry = event_selection_rule.time_framed? ? KEY_EXPIRY_LENGTH : nil

        # Overrides for legacy keys of total counters are handled in `increment`
        increment(event_selection_rule.redis_key_for_date, expiry: expiry)
      end

      def update_unique_counter(event_selection_rule, kwargs)
        identifier_name = event_selection_rule.unique_identifier_name

        unless kwargs[identifier_name]
          message = "#{event_selection_rule.name} should be triggered with a named parameter '#{identifier_name}'."
          Gitlab::AppJsonLogger.warn(message: message)
          return
        end

        unique_value = kwargs[identifier_name].id

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
          user_id: user&.id,
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
    end
  end
end
