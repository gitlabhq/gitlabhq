# frozen_string_literal: true

module Gitlab
  module Tracking
    class EventDefinitionValidator
      EVENT_SCHEMA_PATH = Rails.root.join('config/events/schema.json')
      SCHEMA = ::JSONSchemer.schema(EVENT_SCHEMA_PATH)

      def initialize(definition)
        @attributes = definition.attributes
        @path = definition.path
      end

      def validation_errors
        SCHEMA.validate(attributes.deep_stringify_keys).map do |error|
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
