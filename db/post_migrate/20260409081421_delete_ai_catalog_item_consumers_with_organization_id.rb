# frozen_string_literal: true

class DeleteAiCatalogItemConsumersWithOrganizationId < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.11'

  def up
    define_batchable_model(:ai_catalog_item_consumers).where.not(organization_id: nil).delete_all
  end

  def down
    # no-op - deleted rows cannot be restored
  end
end
