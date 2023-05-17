# frozen_string_literal: true

module Peek
  module Views
    class Zoekt < DetailedView
      DEFAULT_THRESHOLDS = {
        calls: 3,
        duration: 500,
        individual_call: 500
      }.freeze

      THRESHOLDS = {
        production: {
          calls: 5,
          duration: 1000,
          individual_call: 1000
        }
      }.freeze

      def key
        'zkt'
      end

      def self.thresholds
        @thresholds ||= THRESHOLDS.fetch(Rails.env.to_sym, DEFAULT_THRESHOLDS)
      end

      private

      def duration
        ::Gitlab::Instrumentation::Zoekt.query_time * 1000
      end

      def calls
        ::Gitlab::Instrumentation::Zoekt.get_request_count
      end

      def call_details
        ::Gitlab::Instrumentation::Zoekt.detail_store
      end

      def format_call_details(call)
        super.merge(request: "#{call[:method]} #{call[:path]}?#{(call[:params] || {}).to_query}")
      end
    end
  end
end
