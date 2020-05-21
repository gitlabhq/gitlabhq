# frozen_string_literal: true

module Peek
  module Views
    class Gitaly < DetailedView
      DEFAULT_THRESHOLDS = {
        calls: 30,
        duration: 1000,
        individual_call: 500
      }.freeze

      THRESHOLDS = {
        production: {
          calls: 30,
          duration: 1000,
          individual_call: 500
        }
      }.freeze

      def self.thresholds
        @thresholds ||= THRESHOLDS.fetch(Rails.env.to_sym, DEFAULT_THRESHOLDS)
      end

      private

      def duration
        ::Gitlab::GitalyClient.query_time * 1000
      end

      def calls
        ::Gitlab::GitalyClient.get_request_count
      end

      def call_details
        ::Gitlab::GitalyClient.list_call_details
      end

      def format_call_details(call)
        pretty_request = call[:request]&.reject { |k, v| v.blank? }.to_h.pretty_inspect

        super.merge(request: pretty_request || {})
      end
    end
  end
end
