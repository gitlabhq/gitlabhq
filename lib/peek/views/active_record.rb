# frozen_string_literal: true

module Peek
  module Views
    class ActiveRecord < DetailedView
      DEFAULT_THRESHOLDS = {
        calls: 100,
        duration: 3000,
        individual_call: 1000
      }.freeze

      THRESHOLDS = {
        production: {
          calls: 100,
          duration: 15000,
          individual_call: 5000
        }
      }.freeze

      def self.thresholds
        @thresholds ||= THRESHOLDS.fetch(Rails.env.to_sym, DEFAULT_THRESHOLDS)
      end

      private

      def setup_subscribers
        super

        subscribe('sql.active_record') do |_, start, finish, _, data|
          if Gitlab::PerformanceBar.enabled_for_request?
            unless data[:cached]
              detail_store << {
                duration: finish - start,
                sql: data[:sql].strip,
                backtrace: Gitlab::BacktraceCleaner.clean_backtrace(caller)
              }
            end
          end
        end
      end
    end
  end
end
