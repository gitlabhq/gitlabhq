# frozen_string_literal: true

class RemoveOrgIdFromAiCatalogItemConsumersMultiColumnNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint :ai_catalog_item_consumers, :group_id, :project_id

    remove_multi_column_not_null_constraint :ai_catalog_item_consumers, :group_id, :organization_id, :project_id
  end

  def down
    add_multi_column_not_null_constraint :ai_catalog_item_consumers, :group_id, :organization_id, :project_id

    remove_multi_column_not_null_constraint :ai_catalog_item_consumers, :group_id, :project_id
  end
end
