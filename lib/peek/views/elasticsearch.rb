# frozen_string_literal: true

module Peek
  module Views
    class Elasticsearch < DetailedView
      DEFAULT_THRESHOLDS = {
        calls: 5,
        duration: 1000,
        individual_call: 1000
      }.freeze

      THRESHOLDS = {
        production: {
          calls: 5,
          duration: 1000,
          individual_call: 1000
        }
      }.freeze

      def key
        'es'
      end

      def self.thresholds
        @thresholds ||= THRESHOLDS.fetch(Rails.env.to_sym, DEFAULT_THRESHOLDS)
      end

      private

      def duration
        ::Gitlab::Instrumentation::ElasticsearchTransport.query_time * 1000
      end

      def calls
        ::Gitlab::Instrumentation::ElasticsearchTransport.get_request_count
      end

      def call_details
        ::Gitlab::Instrumentation::ElasticsearchTransport.detail_store
      end

      def format_call_details(call)
        super.merge(request: "#{call[:method]} #{call[:path]}?#{call[:params].to_query}")
      end
    end
  end
end
