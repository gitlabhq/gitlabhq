# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssueAssigneesNamespaceId < BatchedMigrationJob
      cursor :issue_id, :user_id
      operation_name :backfill_issue_assignees_namespace_id
      feature_category :team_planning

      def perform
        each_sub_batch do |relation|
          connection.execute(<<~SQL)
            WITH batched_relation AS (
              #{relation.where(namespace_id: nil).select(:issue_id, :user_id).to_sql}
            )
            UPDATE issue_assignees
            SET namespace_id = issues.namespace_id
            FROM batched_relation
            INNER JOIN issues ON batched_relation.issue_id = issues.id
            WHERE issue_assignees.issue_id = batched_relation.issue_id
              AND issue_assignees.user_id = batched_relation.user_id;
          SQL
        end
      end
    end
  end
end
