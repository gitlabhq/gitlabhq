# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Repairs parent links created without their legacy epic_issues row:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/612058
    class BackfillMissingEpicIssuesFromParentLinks < BatchedMigrationJob
      cursor :id

      operation_name :backfill_missing_epic_issues
      feature_category :portfolio_management
      tables_to_check_for_vacuum :epic_issues

      # Batching over epics keeps each query on the smaller driving side: the links are reached
      # through index_work_item_parent_links_on_work_item_parent_id and both anti-joins are
      # index-only scans. Epic children sync through epics.parent_id and never get a row here.
      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            INSERT INTO epic_issues (epic_id, issue_id, relative_position, namespace_id, work_item_parent_link_id)
            SELECT parent_epics.id, links.work_item_id, links.relative_position, issues.namespace_id, links.id
            FROM epics parent_epics
            INNER JOIN work_item_parent_links links ON links.work_item_parent_id = parent_epics.issue_id
            INNER JOIN issues ON issues.id = links.work_item_id
            WHERE parent_epics.id IN (#{sub_batch.select(:id).to_sql})
              AND NOT EXISTS (
                SELECT 1 FROM epic_issues WHERE epic_issues.issue_id = links.work_item_id
              )
              AND NOT EXISTS (
                SELECT 1 FROM epics child_epics WHERE child_epics.issue_id = links.work_item_id
              )
            ON CONFLICT DO NOTHING
          SQL
        end
      end
    end
  end
end
