# frozen_string_literal: true

class RemoveAiCatalogFlowRecords < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class AiCatalogItem < MigrationRecord
    self.table_name = 'ai_catalog_items'
  end

  class AiCatalogItemConsumer < MigrationRecord
    self.table_name = 'ai_catalog_item_consumers'
  end

  class AiCatalogItemVersion < MigrationRecord
    self.table_name = 'ai_catalog_item_versions'
  end

  class AiDuoWorkflowsWorkflow < MigrationRecord
    self.table_name = 'duo_workflows_workflows'
  end

  def up
    AiCatalogItem.transaction do
      flows = AiCatalogItem.where(item_type: 2)
      flow_item_consumers = AiCatalogItemConsumer.where(ai_catalog_item_id: flows.pluck(:id))
      flow_versions = AiCatalogItemVersion.where(ai_catalog_item_id: flows.pluck(:id))
      duo_workflows_workflows = AiDuoWorkflowsWorkflow.where(ai_catalog_item_version_id: flow_versions.pluck(:id))

      duo_workflows_workflows.delete_all
      flow_item_consumers.delete_all
      flows.delete_all
    end
  end

  def down
    # no-op
  end
end
