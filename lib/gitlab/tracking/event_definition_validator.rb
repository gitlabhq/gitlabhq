# frozen_string_literal: true

module Gitlab
  module Tracking
    class EventDefinitionValidator
      EVENT_SCHEMA_PATH = Rails.root.join('config/events/schema.json')
      SCHEMA = ::JSONSchemer.schema(EVENT_SCHEMA_PATH)
      NOT_VALIDATED_PROPERTIES = [:value].freeze

      def initialize(definition)
        @attributes = definition.attributes
        @path = definition.path
      end

      def validation_errors
        (validate_schema << validate_additional_properties).compact
      end

      private

      attr_reader :attributes, :path

      def validate_additional_properties
        additional_props = attributes[:additional_properties]&.map { |k, _| k }

        return unless additional_props.present?

        extra_props = additional_props - Gitlab::InternalEvents::BASE_ADDITIONAL_PROPERTIES.keys
        unused_props = prioritized_properties - additional_props

        return unless extra_props.present? && unused_props.present?

        <<~ERROR_MSG
          --------------- VALIDATION ERROR ---------------
          Definition file: #{path}
          Error type: consider using the built-in additional properties:
          "#{prioritized_properties.join(', ')}"
          before adding custom extra properties: #{extra_props.join(', ')}
        ERROR_MSG
      end

      def prioritized_properties
        Gitlab::InternalEvents::BASE_ADDITIONAL_PROPERTIES.keys - NOT_VALIDATED_PROPERTIES
      end

      def validate_schema
        SCHEMA.validate(attributes.deep_stringify_keys).map do |error|
          <<~ERROR_MSG
            --------------- VALIDATION ERROR ---------------
            Definition file: #{path}
            Error type: #{error['type']}
            Data: #{error['data']}
            Path: #{error['data_pointer']}
            Details: #{error['details']}
          ERROR_MSG
        end
      end
    end
  end
end
