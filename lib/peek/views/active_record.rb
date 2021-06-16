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

      def results
        super.merge(summary: summary)
      end

      private

      def summary
        detail_store.each_with_object({}) do |item, count|
          count_summary(item, count)
        end
      end

      def count_summary(item, count)
        if item[:cached].present?
          count[item[:cached]] ||= 0
          count[item[:cached]] += 1
        end

        if item[:transaction].present?
          count[item[:transaction]] ||= 0
          count[item[:transaction]] += 1
        end

        if ::Gitlab::Database::LoadBalancing.enable?
          count[item[:db_role]] ||= 0
          count[item[:db_role]] += 1
        end
      end

      def setup_subscribers
        super

        subscribe('sql.active_record') do |_, start, finish, _, data|
          detail_store << generate_detail(start, finish, data) if Gitlab::PerformanceBar.enabled_for_request?
        end
      end

      def generate_detail(start, finish, data)
        {
          start: start,
          duration: finish - start,
          sql: data[:sql].strip,
          backtrace: Gitlab::BacktraceCleaner.clean_backtrace(caller),
          cached: data[:cached] ? 'Cached' : '',
          transaction: data[:connection].transaction_open? ? 'In a transaction' : '',
          db_role: db_role(data)
        }
      end

      def db_role(data)
        return unless ::Gitlab::Database::LoadBalancing.enable?

        role = ::Gitlab::Database::LoadBalancing.db_role_for_connection(data[:connection]) ||
          ::Gitlab::Database::LoadBalancing::ROLE_UNKNOWN

        role.to_s.capitalize
      end
    end
  end
end
