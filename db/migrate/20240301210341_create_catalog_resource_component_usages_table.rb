# frozen_string_literal: true

class CreateCatalogResourceComponentUsagesTable < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  enable_lock_retries!

  CATALOG_RESOURCE_INDEX_NAME = 'idx_p_catalog_resource_component_usages_on_catalog_resource_id'
  UNIQUE_INDEX_NAME = 'idx_component_usages_on_component_used_by_project_and_used_date'

  def up
    options = {
      primary_key: [:id, :used_date],
      options: 'PARTITION BY RANGE (used_date)',
      if_not_exists: true
    }

    create_table(:p_catalog_resource_component_usages, **options) do |t|
      t.bigserial :id, null: false
      t.bigint :component_id, null: false
      t.bigint :catalog_resource_id, null: false
      t.bigint :project_id, null: false, index: true
      t.bigint :used_by_project_id, null: false
      t.date :used_date, null: false

      t.index :catalog_resource_id, name: CATALOG_RESOURCE_INDEX_NAME
      t.index [:component_id, :used_by_project_id, :used_date], unique: true, name: UNIQUE_INDEX_NAME
    end
  end

  def down
    drop_table :p_catalog_resource_component_usages
  end
end
