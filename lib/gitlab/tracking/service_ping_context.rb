# frozen_string_literal: true

module Gitlab
  module Tracking
    class ServicePingContext
      SCHEMA_URL = 'iglu:com.gitlab/gitlab_service_ping/jsonschema/1-0-0'
      ALLOWED_SOURCES = %i[redis_hll].freeze

      def initialize(data_source:, event:)
        unless ALLOWED_SOURCES.include?(data_source)
          raise ArgumentError, "#{data_source} is not acceptable data source for ServicePingContext"
        end

        @payload = {
          data_source: data_source,
          event_name: event
        }
      end

      def to_context
        SnowplowTracker::SelfDescribingJson.new(SCHEMA_URL, @payload)
      end

      def to_h
        {
          schema: SCHEMA_URL,
          data: @payload
        }
      end
    end
  end
end
