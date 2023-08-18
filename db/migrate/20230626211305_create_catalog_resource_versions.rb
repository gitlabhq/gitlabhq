# frozen_string_literal: true

class CreateCatalogResourceVersions < Gitlab::Database::Migration[2.1]
  def change
    create_table :catalog_resource_versions do |t|
      t.bigint :release_id, null: false, index: { unique: true }
      t.bigint :catalog_resource_id, null: false, index: true
      t.bigint :project_id, null: false, index: true

      t.datetime_with_timezone :created_at, null: false
    end
  end
end
