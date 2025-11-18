# frozen_string_literal: true

module Gitlab
  module Observability
    class OtelExporter
      include Gitlab::Utils::StrongMemoize

      ExportError = Class.new(StandardError)
      AuthenticationError = Class.new(ExportError)
      NetworkError = Class.new(ExportError)

      ENDPOINTS = {
        traces: '/v1/traces',
        metrics: '/v1/metrics',
        logs: '/v1/logs'
      }.freeze

      def initialize(integration)
        @integration = integration

        unless integration.respond_to?(:otel_endpoint_url) && integration.respond_to?(:otel_headers)
          raise ArgumentError, "Integration must respond to otel_endpoint_url and otel_headers"
        end

        @endpoint_url = integration.otel_endpoint_url
        @headers = integration.otel_headers
      end

      def export_traces(traces_data)
        export_data(:traces, traces_data)
      end

      def export_metrics(metrics_data)
        export_data(:metrics, metrics_data)
      end

      def export_logs(logs_data)
        export_data(:logs, logs_data)
      end

      private

      attr_reader :integration, :endpoint_url, :headers

      def export_data(type, data)
        return if data.blank?
        return unless @endpoint_url.present?

        endpoint = build_endpoint(type)
        payload = build_payload(type, data)

        response = send_request(endpoint, payload)
        handle_response(response)
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        raise NetworkError, "Failed to export #{type} to OTEL endpoint: #{e.message}"
      end

      def build_endpoint(type)
        base_url = endpoint_url.chomp('/')
        path = ENDPOINTS[type]
        "#{base_url}#{path}"
      end

      def build_payload(type, data)
        case type
        when :traces
          build_traces_payload(data)
        when :metrics
          build_metrics_payload(data)
        when :logs
          build_logs_payload(data)
        else
          raise ArgumentError, "Unknown export type: #{type}"
        end
      end

      def build_traces_payload(traces_data)
        {
          resourceSpans: traces_data[:resourceSpans] || []
        }
      end

      def build_metrics_payload(metrics_data)
        {
          resourceMetrics: metrics_data[:resourceMetrics] || []
        }
      end

      def build_logs_payload(logs_data)
        {
          resourceLogs: logs_data[:resourceLogs] || []
        }
      end

      def send_request(endpoint, payload)
        Gitlab::HTTP.post(
          endpoint,
          headers: request_headers,
          body: Gitlab::Json.dump(payload),
          timeout: 30.seconds,
          allow_local_requests: allow_local_requests?
        )
      end

      def request_headers
        {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }.merge(headers)
      end

      def handle_response(response)
        case response.code.to_i
        when 200..299
          response
        when 401, 403
          raise AuthenticationError, "Authentication failed for OTEL endpoint (HTTP #{response.code})"
        when 429
          Gitlab::AppLogger.warn(
            message: "Rate limited by OTEL endpoint",
            integration: integration.class.name,
            endpoint: endpoint_url,
            response_code: response.code
          )
          response
        else
          raise ExportError, "OTEL endpoint returned error #{response.code}"
        end
      end

      def allow_local_requests?
        Rails.env.development? ||
          Rails.env.test? ||
          Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
      end
    end
  end
end
