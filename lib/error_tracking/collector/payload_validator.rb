# frozen_string_literal: true

module ErrorTracking
  module Collector
    class PayloadValidator
      PAYLOAD_SCHEMA_PATH = Rails.root.join('app', 'validators', 'json_schemas', 'error_tracking_event_payload.json').to_s

      def valid?(payload)
        JSONSchemer.schema(Pathname.new(PAYLOAD_SCHEMA_PATH)).valid?(payload)
      end
    end
  end
end
