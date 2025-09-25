# frozen_string_literal: true

module Gitlab
  module Lograge
    module CustomOptions
      include ::Gitlab::Logging::CloudflareHelper
      include ::Gitlab::Logging::JsonMetadataHelper

      LIMITED_ARRAY_SENTINEL = { key: 'truncated', value: '...' }.freeze
      IGNORE_PARAMS = Set.new(%w[controller action format]).freeze
      KNOWN_PAYLOAD_PARAMS = [:remote_ip, :user_id, :username, :ua, :queue_duration_s,
                              :etag_route, :request_urgency, :target_duration_s] + \
        CLOUDFLARE_CUSTOM_HEADERS.values + \
        JSON_METADATA_HEADERS

      def self.call(event)
        params = event
          .payload[:params]
          .each_with_object([]) { |(k, v), array| array << { key: k, value: v } unless IGNORE_PARAMS.include?(k) }
        payload = {
          time: Time.now.utc.iso8601(3),
          params: Gitlab::Utils::LogLimitedArray.log_limited_array(params, sentinel: LIMITED_ARRAY_SENTINEL)
        }

        payload.merge!(event.payload[:metadata]) if event.payload[:metadata]
        optional_payload_params = event.payload.slice(*KNOWN_PAYLOAD_PARAMS).compact
        payload.merge!(optional_payload_params)

        # Add JSON metadata params (they have json_ prefix)
        json_metadata_params = event.payload.select { |key, _| key.to_s.start_with?('json_') }
        payload.merge!(json_metadata_params)

        ::Gitlab::InstrumentationHelper.add_instrumentation_data(payload)

        payload[Labkit::Correlation::CorrelationId::LOG_KEY] = event.payload[Labkit::Correlation::CorrelationId::LOG_KEY] || Labkit::Correlation::CorrelationId.current_id

        # https://github.com/roidrage/lograge#logging-errors--exceptions
        exception = event.payload[:exception_object]

        ::Gitlab::ExceptionLogFormatter.format!(exception, payload)

        if Feature.enabled?(:feature_flag_state_logs)
          payload[:feature_flag_states] = Feature.logged_states.map { |key, state| "#{key}:#{state ? 1 : 0}" }
        end

        payload
      end
    end
  end
end
