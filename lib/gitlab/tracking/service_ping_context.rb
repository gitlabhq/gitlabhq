# frozen_string_literal: true

module Gitlab
  module Tracking
    class ServicePingContext
      SCHEMA_URL = 'iglu:com.gitlab/gitlab_service_ping/jsonschema/1-0-1'
      REDISHLL_SOURCE = :redis_hll
      REDIS_SOURCE = :redis

      ALLOWED_SOURCES = [REDISHLL_SOURCE, REDIS_SOURCE].freeze

      def initialize(data_source:, event: nil)
        check_configuration(data_source, event)

        @payload = { data_source: data_source }

        payload[:event_name] = event
      end

      def to_context
        SnowplowTracker::SelfDescribingJson.new(SCHEMA_URL, payload)
      end

      def to_h
        {
          schema: SCHEMA_URL,
          data: @payload
        }
      end

      private

      attr_reader :payload

      def check_configuration(data_source, event)
        unless ALLOWED_SOURCES.include?(data_source.to_sym)
          configuration_error("#{data_source} is not acceptable data source for ServicePingContext")
        end

        return unless event.nil?

        configuration_error("event attribute is required")
      end

      def configuration_error(message)
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ArgumentError.new(message))
      end
    end
  end
end
