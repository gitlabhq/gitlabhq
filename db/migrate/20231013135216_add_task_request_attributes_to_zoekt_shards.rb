# frozen_string_literal: true

class AddTaskRequestAttributesToZoektShards < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  UNIQUE_UUID_INDEX = 'unique_zoekt_shards_uuid'
  LAST_SEEN_AT_INDEX = 'index_zoekt_shards_on_last_seen_at'

  def up
    add_column :zoekt_shards, :uuid, :uuid, null: false, default: '00000000-00000000-00000000-00000000'
    add_column :zoekt_shards, :last_seen_at, :datetime_with_timezone, null: false, default: '1970-01-01'
    add_column :zoekt_shards, :used_bytes, :bigint, null: false, default: 0
    add_column :zoekt_shards, :total_bytes, :bigint, null: false, default: 0
    add_column :zoekt_shards, :metadata, :jsonb, default: {}, null: false

    add_concurrent_index :zoekt_shards, :uuid, unique: true, name: UNIQUE_UUID_INDEX
    add_concurrent_index :zoekt_shards, :last_seen_at, name: LAST_SEEN_AT_INDEX
  end

  def down
    remove_column :zoekt_shards, :uuid
    remove_column :zoekt_shards, :last_seen_at
    remove_column :zoekt_shards, :used_bytes
    remove_column :zoekt_shards, :total_bytes
    remove_column :zoekt_shards, :metadata

    remove_concurrent_index :zoekt_shards, :uuid, name: UNIQUE_UUID_INDEX
    remove_concurrent_index :zoekt_shards, :last_seen_at, name: LAST_SEEN_AT_INDEX
  end
end
