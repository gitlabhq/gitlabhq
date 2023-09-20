# frozen_string_literal: true

module Peek
  module Views
    class ClickHouse < DetailedView
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
        'ch'
      end

      def self.thresholds
        @thresholds ||= THRESHOLDS.fetch(Rails.env.to_sym, DEFAULT_THRESHOLDS)
      end

      private

      def setup_subscribers
        super

        subscribe('sql.click_house') do |_, start, finish, _, data|
          detail_store << generate_detail(start, finish, data) if Gitlab::PerformanceBar.enabled_for_request?
        end
      end

      def generate_detail(start, finish, data)
        {
          start: start,
          duration: finish - start,
          sql: data[:query].to_sql.strip,
          backtrace: Gitlab::BacktraceCleaner.clean_backtrace(caller),
          database: "database: #{data[:database]}",
          statistics: "query stats: #{data[:statistics]}"
        }
      end
    end
  end
end
