# frozen_string_literal: true

module Gitlab
  module Lograge
    module CustomOptions
      include ::Gitlab::Logging::CloudflareHelper
      include ::Gitlab::Logging::JsonMetadataHelper

      LIMITED_ARRAY_SENTINEL = { key: 'truncated', value: '...' }.freeze
      IGNORE_PARAMS = Set.new(%w[controller action format]).freeze
      KNOWN_PAYLOAD_PARAMS = [:remote_ip, :user_id, :username, :user_is_bot, :ua, :queue_duration_s,
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

        apdex_duration = ::Gitlab::RequestContext.apdex_duration_s
        payload[:apdex_duration_s] = apdex_duration if apdex_duration

        payload[Labkit::Fields::CORRELATION_ID] = event.payload[Labkit::Fields::CORRELATION_ID] || Labkit::Correlation::CorrelationId.current_id

        duo_workflow_id = Gitlab::ApplicationContext.current_context_attribute(:duo_workflow_id)
        payload[Labkit::Fields::DUO_WORKFLOW_ID] = duo_workflow_id if duo_workflow_id

        # https://github.com/roidrage/lograge#logging-errors--exceptions
        exception = event.payload[:exception_object]

        ::Gitlab::ExceptionLogFormatter.format!(exception, payload)

        if Feature.enabled?(:feature_flag_state_logs)
          formatted = Feature.logged_states_for_log
          payload[:feature_flag_states] = formatted unless formatted.empty?
        end

        payload
      end
    end
  end
end
