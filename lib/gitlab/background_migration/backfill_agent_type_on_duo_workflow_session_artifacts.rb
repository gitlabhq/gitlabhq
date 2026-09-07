# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Copies duo_workflows_workflows.agent_type onto artifacts synced before the
    # column existed; completed sessions never re-sync, so nothing else fills them.
    class BackfillAgentTypeOnDuoWorkflowSessionArtifacts < BatchedMigrationJob
      operation_name :backfill_agent_type
      feature_category :compliance_management
      cursor :id

      def perform
        each_sub_batch do |sub_batch|
          result = connection.execute(<<~SQL)
            WITH sub_batch AS MATERIALIZED (
              #{sub_batch.select(:id).limit(sub_batch_size).to_sql}
            )
            UPDATE duo_workflow_session_artifacts
            SET agent_type = duo_workflows_workflows.agent_type
            FROM duo_workflows_workflows
            WHERE duo_workflow_session_artifacts.id IN (SELECT id FROM sub_batch)
              AND duo_workflows_workflows.id = duo_workflow_session_artifacts.workflow_id
              AND duo_workflow_session_artifacts.agent_type IS NULL
              AND duo_workflows_workflows.agent_type IS NOT NULL
          SQL

          result.cmd_tuples
        end
      end
    end
  end
end
