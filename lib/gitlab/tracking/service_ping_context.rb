# frozen_string_literal: true

module Gitlab
  module Tracking
    class ServicePingContext
      SCHEMA_URL = 'iglu:com.gitlab/gitlab_service_ping/jsonschema/1-0-0'
      REDISHLL_SOURCE = :redis_hll
      REDIS_SOURCE = :redis

      ALLOWED_SOURCES = [REDISHLL_SOURCE, REDIS_SOURCE].freeze

      def initialize(data_source:, event: nil, key_path: nil)
        check_configuration(data_source, event, key_path)

        @payload = { data_source: data_source }

        payload[:event_name] = event if data_source.eql? REDISHLL_SOURCE
        payload[:key_path] = key_path if data_source.eql? REDIS_SOURCE
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

      def check_configuration(data_source, event, key_path)
        unless ALLOWED_SOURCES.include?(data_source)
          configuration_error("#{data_source} is not acceptable data source for ServicePingContext")
        end

        if REDISHLL_SOURCE.eql?(data_source) && event.nil?
          configuration_error("event attribute can not be missing for #{REDISHLL_SOURCE} data source")
        end

        return unless REDIS_SOURCE.eql?(data_source) && key_path.nil?

        configuration_error("key_path attribute can not be missing for #{REDIS_SOURCE} data source")
      end

      def configuration_error(message)
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ArgumentError.new(message))
      end
    end
  end
end
