# frozen_string_literal: true

class CreateSecurityInventoryFilters < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  PROJECT_ID_FK_INDEX_NAME = 'index_security_inventory_filters_on_project_id'

  def up
    create_table :security_inventory_filters do |t|
      t.boolean :archived, null: false, default: false

      # analyzer statuses
      t.column :sast, :smallint, default: 0, null: false
      t.column :sast_advanced, :smallint, default: 0, null: false
      t.column :sast_iac, :smallint, default: 0, null: false
      t.column :dast, :smallint, default: 0, null: false
      t.column :dependency_scanning, :smallint, default: 0, null: false
      t.column :coverage_fuzzing, :smallint, default: 0, null: false
      t.column :api_fuzzing, :smallint, default: 0, null: false
      t.column :cluster_image_scanning, :smallint, default: 0, null: false
      t.column :secret_detection_secret_push_protection, :smallint, default: 0, null: false
      t.column :container_scanning_for_registry, :smallint, default: 0, null: false
      t.column :secret_detection_pipeline_based, :smallint, default: 0, null: false
      t.column :container_scanning_pipeline_based, :smallint, default: 0, null: false
      t.column :secret_detection, :smallint, default: 0, null: false
      t.column :container_scanning, :smallint, default: 0, null: false

      # vulnerability counts
      t.integer :total, default: 0, null: false
      t.integer :critical, default: 0, null: false
      t.integer :high, default: 0, null: false
      t.integer :medium, default: 0, null: false
      t.integer :low, default: 0, null: false
      t.integer :info, default: 0, null: false
      t.integer :unknown, default: 0, null: false

      t.bigint :project_id, null: false, index: { name: PROJECT_ID_FK_INDEX_NAME, unique: true }
      t.bigint :traversal_ids, array: true, default: [], null: false
      t.text :project_name, null: false, limit: 255
    end
  end

  def down
    drop_table :security_inventory_filters
  end
end
