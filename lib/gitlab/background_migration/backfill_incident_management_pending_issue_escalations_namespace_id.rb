# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIncidentManagementPendingIssueEscalationsNamespaceId < BatchedMigrationJob
      operation_name :backfill_incident_management_pending_issue_escalations_namespace_id
      feature_category :incident_management
      cursor :id, :process_at

      def perform
        each_sub_batch do |relation|
          connection.execute(<<~SQL)
            WITH batched_relation AS (
              #{relation.where(namespace_id: nil).select(:id, :process_at).to_sql}
            )
            UPDATE incident_management_pending_issue_escalations
            SET namespace_id = issues.namespace_id
            FROM batched_relation
            INNER JOIN issues ON batched_relation.id = issues.id
            WHERE incident_management_pending_issue_escalations.id = batched_relation.id
              AND incident_management_pending_issue_escalations.process_at = batched_relation.process_at;
          SQL
        end
      end
    end
  end
end
