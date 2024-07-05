# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssuesDatesWithWorkItemDatesSources < BatchedMigrationJob
      operation_name :backfill_issues_dates_with_work_item_dates_source
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          inner_scope = sub_batch.select(:start_date, :due_date, :issue_id)

          define_batchable_model('issues', connection: ApplicationRecord.connection).connection.execute <<~SQL
            WITH work_item_dates_sources_date_values AS MATERIALIZED (
              #{inner_scope.to_sql}
            )
            UPDATE issues
            SET
              start_date = work_item_dates_sources_date_values.start_date,
              due_date = work_item_dates_sources_date_values.due_date
            FROM
              work_item_dates_sources_date_values
            WHERE
              work_item_dates_sources_date_values.issue_id = issues.id
              AND work_item_dates_sources_date_values.start_date IS DISTINCT FROM issues.start_date
              AND work_item_dates_sources_date_values.due_date IS DISTINCT FROM issues.due_date
          SQL
        end
      end
    end
  end
end
