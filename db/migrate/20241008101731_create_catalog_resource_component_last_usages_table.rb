# frozen_string_literal: true

class CreateCatalogResourceComponentLastUsagesTable < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  enable_lock_retries!

  CATALOG_RESOURCE_INDEX_NAME = 'idx_cpmt_last_usages_on_catalog_resource_id'
  UNIQUE_INDEX_NAME = 'idx_usages_on_cmpt_used_by_project_cmpt_and_last_used_date'
  PROJECT_INDEX_NAME = 'idx_catalog_resource_cpmt_last_usages_on_cpmt_project_id'

  def up
    create_table :catalog_resource_component_last_usages do |t|
      t.bigint :component_id, null: false
      t.bigint :catalog_resource_id, null: false
      t.bigint :component_project_id, null: false
      t.bigint :used_by_project_id, null: false
      t.date :last_used_date, null: false

      t.index :catalog_resource_id, name: CATALOG_RESOURCE_INDEX_NAME
      t.index [:component_id, :used_by_project_id, :last_used_date], unique: true, name: UNIQUE_INDEX_NAME
      t.index :component_project_id, name: PROJECT_INDEX_NAME
    end
  end

  def down
    drop_table :catalog_resource_component_last_usages
  end
end
