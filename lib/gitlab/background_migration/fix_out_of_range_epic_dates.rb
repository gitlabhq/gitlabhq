# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixOutOfRangeEpicDates < BatchedMigrationJob
      feature_category :team_planning

      operation_name :fix_epics_with_dates_out_of_elastic_search_range

      # rubocop:disable Database/AvoidScopeTo -- There's a small number of rows expected to be updated
      scope_to ->(relation) {
        relation.where <<~SQL, max_date: ::WorkItems::DatesSource::MAX_DATE_LIMIT
          start_date > :max_date
          OR start_date_fixed > :max_date
          OR end_date > :max_date
          OR due_date_fixed > :max_date
        SQL
      }
      # rubocop:enable Database/AvoidScopeTo

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(<<~SQL)
          start_date = LEAST(start_date, '9999-12-31'::date),
          start_date_fixed = LEAST(start_date_fixed, '9999-12-31'::date),
          end_date = LEAST(end_date, '9999-12-31'::date),
          due_date_fixed = LEAST(due_date_fixed, '9999-12-31'::date)
          SQL
        end
      end
    end
  end
end
