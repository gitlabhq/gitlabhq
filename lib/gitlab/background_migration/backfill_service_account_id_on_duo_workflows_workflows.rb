# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillServiceAccountIdOnDuoWorkflowsWorkflows < BatchedMigrationJob
      operation_name :backfill_service_account_id_on_duo_workflows_workflows
      feature_category :duo_agent_platform

      def perform
        each_sub_batch do |sub_batch|
          backfill_service_account_id(sub_batch)
        end
      end

      private

      def backfill_service_account_id(id_sub_batch)
        connection.execute(backfill_sql(id_sub_batch))
      end

      def backfill_sql(id_sub_batch)
        <<~SQL
          UPDATE duo_workflows_workflows dww
          SET service_account_id = (
            SELECT aic.service_account_id
            FROM ai_catalog_item_consumers aic
            WHERE aic.service_account_id IS NOT NULL
            AND aic.ai_catalog_item_id = COALESCE(
              (SELECT aiv.ai_catalog_item_id
               FROM ai_catalog_item_versions aiv
               WHERE aiv.id = dww.ai_catalog_item_version_id),
              (SELECT item.id
               FROM ai_catalog_items item
               WHERE item.foundational_flow_reference = dww.workflow_definition
               LIMIT 1)
            )
            AND aic.group_id = (
              SELECT traversal_ids[1]
              FROM namespaces
              WHERE id = COALESCE(
                (SELECT namespace_id FROM projects WHERE id = dww.project_id),
                dww.namespace_id
              )
            )
            LIMIT 1
          )
          WHERE dww.id IN (#{id_sub_batch.select(:id).to_sql})
          AND dww.service_account_id IS NULL
        SQL
      end
    end
  end
end
