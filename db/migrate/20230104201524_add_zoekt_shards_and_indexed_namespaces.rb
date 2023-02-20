# frozen_string_literal: true

class AddZoektShardsAndIndexedNamespaces < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :zoekt_shards do |t|
      t.text :index_base_url, limit: 1024, index: { unique: true }, null: false
      t.text :search_base_url, limit: 1024, index: { unique: true }, null: false
      t.timestamps_with_timezone
    end

    create_table :zoekt_indexed_namespaces do |t|
      t.references :zoekt_shard, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.bigint :namespace_id, null: false, index: true
      t.timestamps_with_timezone
      t.index [:zoekt_shard_id, :namespace_id], unique: true, name: 'index_zoekt_shard_and_namespace'
    end
  end
end
