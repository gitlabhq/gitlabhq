# frozen_string_literal: true

class AddAiCatalogItemConsumersMultiColumnNotNull < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    add_multi_column_not_null_constraint(:ai_catalog_item_consumers, :organization_id, :group_id, :project_id)
  end

  def down
    remove_multi_column_not_null_constraint(:ai_catalog_item_consumers, :organization_id, :group_id, :project_id)
  end
end
