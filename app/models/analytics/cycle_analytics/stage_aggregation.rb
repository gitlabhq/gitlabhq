# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StageAggregation < ApplicationRecord
      include Analytics::CycleAnalytics::Parentable

      STATS_SIZE_LIMIT = 10

      belongs_to :stage, class_name: 'Analytics::CycleAnalytics::Stage', optional: false, inverse_of: :stage_aggregation

      validates :runtimes_in_seconds, :processed_records,
        presence: true, length: { maximum: STATS_SIZE_LIMIT }, allow_blank: true

      scope :enabled, -> { where(enabled: true) }
      scope :prioritized, -> { order(arel_table[:last_run_at].asc.nulls_first) }
      scope :incomplete, -> { where(last_completed_at: nil) }

      def self.load_batch(batch_size = 100)
        enabled.incomplete.prioritized.limit(batch_size)
      end

      def cursor_for(model)
        {
          updated_at: self["last_#{model.table_name}_updated_at"],
          id: self["last_#{model.table_name}_id"]
        }.compact
      end

      def set_cursor(model, cursor)
        self["last_#{model.table_name}_id"] = cursor[:id]
        self["last_#{model.table_name}_updated_at"] = cursor[:updated_at]
      end

      def refresh_last_run
        self.last_run_at = Time.current
      end

      def set_stats(runtime, processed_records)
        # We only store the last 10 data points
        self.runtimes_in_seconds = (runtimes_in_seconds + [runtime]).last(STATS_SIZE_LIMIT)
        self.processed_records = (self.processed_records + [processed_records]).last(STATS_SIZE_LIMIT)
      end

      def complete
        self.last_completed_at = Time.current
      end
    end
  end
end
