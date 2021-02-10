# frozen_string_literal: true

module Peek
  module Views
    class ExternalHttp < DetailedView
      DEFAULT_THRESHOLDS = {
        calls: 10,
        duration: 1000,
        individual_call: 100
      }.freeze

      THRESHOLDS = {
        production: {
          calls: 10,
          duration: 1000,
          individual_call: 100
        }
      }.freeze

      def key
        'external-http'
      end

      def results
        super.merge(calls: calls)
      end

      def self.thresholds
        @thresholds ||= THRESHOLDS.fetch(Rails.env.to_sym, DEFAULT_THRESHOLDS)
      end

      def format_call_details(call)
        full_path = generate_path(call)
        super.merge(
          label: "#{call[:method]} #{full_path}",
          code: code(call),
          proxy: proxy(call),
          error: error(call)
        )
      end

      private

      def duration
        ::Gitlab::Metrics::Subscribers::ExternalHttp.duration * 1000
      end

      def calls
        ::Gitlab::Metrics::Subscribers::ExternalHttp.request_count
      end

      def call_details
        ::Gitlab::Metrics::Subscribers::ExternalHttp.detail_store
      end

      def proxy(call)
        if call[:proxy_host].present?
          "Proxied via #{call[:proxy_host]}:#{call[:proxy_port]}"
        else
          nil
        end
      end

      def code(call)
        if call[:code].present?
          "Response status: #{call[:code]}"
        else
          nil
        end
      end

      def error(call)
        if call[:exception_object].present?
          "Exception: #{call[:exception_object]}"
        else
          nil
        end
      end

      def generate_path(call)
        uri = URI("")
        uri.scheme = call[:scheme]
        # The host can be a domain, IPv4 or IPv6.
        # Ruby handle IPv6 for us at
        # https://github.com/ruby/ruby/blob/v2_6_0/lib/uri/generic.rb#L662
        uri.hostname = call[:host]
        uri.port = call[:port]
        uri.path = call[:path]
        uri.query = generate_query(call[:query])

        uri.to_s
      rescue StandardError
        'unknown'
      end

      def generate_query(query_string)
        query_string.is_a?(Hash) ? query_string.to_query : query_string.to_s
      end
    end
  end
end
