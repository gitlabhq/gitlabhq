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
        unless Gitlab::Tracking::EventDefinition.internal_event_exists?(event_name)
          raise UnknownEventError, "Unknown event: #{event_name}"
        end

        validate_properties!
        validate_additional_properties!
      end

      private

      attr_reader :event_name, :additional_properties, :kwargs

      def validate_properties!
        validate_property!(kwargs, :user, User)
        validate_property!(kwargs, :namespace, Namespaces::UserNamespace, Group)
        validate_property!(kwargs, :project, Project)
      end

      def validate_property!(hash, key, *class_names)
        return unless hash.has_key?(key)
        return if hash[key].nil?
        return if class_names.include?(hash[key].class)

        raise InvalidPropertyTypeError, "#{key} should be an instance of #{class_names.join(', ')}"
      end

      def validate_additional_properties!
        additional_properties.each_key do |property|
          next unless BASE_ADDITIONAL_PROPERTIES.has_key?(property)

          allowed_classes = BASE_ADDITIONAL_PROPERTIES[property]
          validate_property!(additional_properties, property, *allowed_classes)
        end

        # skip base properties validation. To be done in a separate MR as we have some non-compliant definitions
        custom_properties = additional_properties.except(*BASE_ADDITIONAL_PROPERTIES.keys)
        event_definition_attributes = Gitlab::Tracking::EventDefinition.find(event_name).to_h
        allowed_types = CUSTOM_PROPERTIES_CLASSES

        custom_properties.each_key do |key|
          unless event_definition_attributes[:additional_properties]&.include?(key)
            raise InvalidPropertyError, "Unknown additional property: #{key} for event_name: #{event_name}"
          end

          validate_property!(custom_properties, key, *allowed_types)
        end
      end
    end
  end
end
