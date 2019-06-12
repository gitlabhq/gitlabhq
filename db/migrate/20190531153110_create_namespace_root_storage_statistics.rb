# frozen_string_literal: true

class CreateNamespaceRootStorageStatistics < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    create_table :namespace_root_storage_statistics, id: false, primary_key: :namespace_id do |t|
      t.integer :namespace_id, null: false, primary_key: true
      t.datetime_with_timezone :updated_at, null: false

      t.bigint :repository_size, null: false, default: 0
      t.bigint :lfs_objects_size, null: false, default: 0
      t.bigint :wiki_size, null: false, default: 0
      t.bigint :build_artifacts_size, null: false, default: 0
      t.bigint :storage_size, null: false, default: 0
      t.bigint :packages_size, null: false, default: 0

      t.index :namespace_id, unique: true
      t.foreign_key :namespaces, column: :namespace_id, on_delete: :cascade
    end
  end
end
