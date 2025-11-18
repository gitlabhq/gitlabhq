# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixOutOfRangeWorkItemDates < BatchedMigrationJob
      feature_category :team_planning
      operation_name :fix_work_items_with_dates_out_of_elastic_search_range

      # Copied from ::WorkItems::DatesSource::MAX_DATE_LIMIT
      MAX_DATE_LIMIT = Date.new(9999, 12, 31).freeze

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
          .where(<<~SQL, max_date: MAX_DATE_LIMIT)
            start_date > :max_date
            OR start_date_fixed > :max_date
            OR due_date > :max_date
            OR due_date_fixed > :max_date
          SQL
          .update_all(format(<<~SQL, max_date: MAX_DATE_LIMIT))
            start_date = LEAST(start_date, '%{max_date}'::date),
            start_date_fixed = LEAST(start_date_fixed, '%{max_date}'::date),
            due_date = LEAST(due_date, '%{max_date}'::date),
            due_date_fixed = LEAST(due_date_fixed, '%{max_date}'::date)
          SQL
        end
      end
    end
  end
end
