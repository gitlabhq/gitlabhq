# frozen_string_literal: true

module Gitlab
  module Tracking
    class EventValidator
      UnknownEventError = Class.new(StandardError)
      InvalidPropertyError = Class.new(StandardError)
      InvalidPropertyTypeError = Class.new(StandardError)
      BASE_ADDITIONAL_PROPERTIES = {
        label: [String],
        property: [String],
        value: [Integer, Float]
      }.freeze
      CUSTOM_PROPERTIES_CLASSES = [String, Integer, Float].freeze

      def initialize(event_name, additional_properties, kwargs)
        @event_name = event_name
        @additional_properties = additional_properties
        @kwargs = kwargs
      end

      def validate!
        validate_event_name!
        validate_properties!
        validate_additional_properties!
      end

      private

      attr_reader :event_name, :additional_properties, :kwargs

      def validate_event_name!
        return if Gitlab::Tracking::EventDefinition.internal_event_exists?(event_name)
        return if Gitlab::UsageDataCounters::HLLRedisCounter.legacy_event?(event_name) && !Gitlab.dev_or_test_env?

        raise UnknownEventError, "Unknown event: #{event_name}"
      end

      def validate_properties!
        validate_property!(kwargs, :user, User)
        validate_property!(kwargs, :namespace, Namespaces::UserNamespace, Group)
        validate_property!(kwargs, :project, Project)
      end

      def validate_property!(hash, key, *class_names)
        return unless hash.has_key?(key)
        return if hash[key].nil?
        return if class_names.include?(hash[key].class)

        error = InvalidPropertyTypeError.new("#{key} should be an instance of #{class_names.join(', ')}")
        log_invalid_property(error)
      end

      def validate_additional_properties!
        event_definition = Gitlab::Tracking::EventDefinition.find(event_name)

        additional_properties.each_key do |property|
          unless event_definition.additional_properties.has_key?(property)
            Gitlab::AppJsonLogger.warn("Tracking event: #{event_name}, undocumented property: #{property}")
          end

          next unless BASE_ADDITIONAL_PROPERTIES.has_key?(property)

          allowed_classes = BASE_ADDITIONAL_PROPERTIES[property]
          validate_property!(additional_properties, property, *allowed_classes)
        end

        # skip base properties validation. To be done in a separate MR as we have some non-compliant definitions
        custom_properties = additional_properties.except(*BASE_ADDITIONAL_PROPERTIES.keys)
        allowed_types = CUSTOM_PROPERTIES_CLASSES

        custom_properties.each_key do |key|
          unless event_definition.additional_properties.has_key?(key)
            error = InvalidPropertyError.new("Unknown additional property: #{key} for event_name: #{event_name}")
            log_invalid_property(error)
          end

          validate_property!(custom_properties, key, *allowed_types)
        end
      end

      def log_invalid_property(error)
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
          error,
          event_name: event_name,
          additional_properties: additional_properties
        )
      end
    end
  end
end
