# frozen_string_literal: true

class AddZoektNodes < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  enable_lock_retries!

  def change
    create_table :zoekt_nodes do |t|
      t.uuid :uuid, index: { unique: true }, null: false
      t.bigint :used_bytes, null: false, default: 0
      t.bigint :total_bytes, null: false, default: 0
      t.datetime_with_timezone :last_seen_at, index: true, null: false, default: '1970-01-01'
      t.timestamps_with_timezone
      t.text :index_base_url, limit: 1024, index: { unique: true }, null: false
      t.text :search_base_url, limit: 1024, index: { unique: true }, null: false
      t.jsonb :metadata, default: {}, null: false
    end
  end
end
