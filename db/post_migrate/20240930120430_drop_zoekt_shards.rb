# frozen_string_literal: true

class DropZoektShards < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  def up
    drop_table :zoekt_shards
  end

  def down
    create_table :zoekt_shards do |t|
      t.text :index_base_url, null: false, limit: 1024
      t.text :search_base_url, null: false, limit: 1024
      t.timestamps_with_timezone
      t.uuid :uuid, null: false, default: '00000000-00000000-00000000-00000000'
      t.datetime_with_timezone :last_seen_at, null: false, default: '1970-01-01'
      t.bigint :used_bytes, null: false, default: 0
      t.bigint :total_bytes, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
    end

    add_concurrent_index :zoekt_shards, :index_base_url, unique: true, name: 'index_zoekt_shards_on_index_base_url'
    add_concurrent_index :zoekt_shards, :last_seen_at, name: 'index_zoekt_shards_on_last_seen_at'
    add_concurrent_index :zoekt_shards, :search_base_url, unique: true, name: 'index_zoekt_shards_on_search_base_url'
    add_concurrent_index :zoekt_shards, :uuid, unique: true, name: 'unique_zoekt_shards_uuid'
  end
end
