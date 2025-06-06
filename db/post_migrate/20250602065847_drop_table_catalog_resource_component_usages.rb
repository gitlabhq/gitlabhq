# frozen_string_literal: true

class DropTableCatalogResourceComponentUsages < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def up
    drop_table :p_catalog_resource_component_usages, if_exists: true, cascade: true
  end

  def down
    options = {
      primary_key: [:id, :used_date],
      options: 'PARTITION BY RANGE (used_date)',
      if_not_exists: true
    }

    create_table(:p_catalog_resource_component_usages, **options) do |t|
      t.bigserial :id, null: false
      t.bigint :component_id, null: false
      t.bigint :catalog_resource_id, null: false
      t.bigint :project_id, null: false
      t.bigint :used_by_project_id, null: false
      t.date :used_date, null: false

      t.index [:catalog_resource_id, :used_by_project_id, :used_date],
        name: 'idx_component_usages_on_catalog_resource_used_by_proj_used_date'
      t.index [:component_id, :used_by_project_id, :used_date],
        unique: true, name: 'idx_component_usages_on_component_used_by_project_and_used_date'
      t.index :project_id, name: 'index_p_catalog_resource_component_usages_on_project_id'
    end
  end
end
