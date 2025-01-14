# frozen_string_literal: true

module Gitlab
  module Tracking
    class EventDefinitionValidator
      EVENT_SCHEMA_PATH = Rails.root.join('config/events/schema.json')

      def self.definition_schema
        @definition_schema ||= ::JSONSchemer.schema(EVENT_SCHEMA_PATH)
      end

      def initialize(definition)
        @attributes = definition.raw_attributes
        @path = definition.path
      end

      def validation_errors
        self.class.definition_schema.validate(attributes.deep_stringify_keys).map do |error|
          <<~ERROR_MSG
            --------------- VALIDATION ERROR ---------------
            Definition file: #{path}
            Error type: #{error['type']}
            Data: #{error['data']}
            Path: #{error['data_pointer']}
            Details: #{error['details'] || error['error']}
          ERROR_MSG
        end
      end

      private

      attr_reader :attributes, :path
    end
  end
end
