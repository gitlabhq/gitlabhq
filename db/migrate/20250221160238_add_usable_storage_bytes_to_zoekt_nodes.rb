# frozen_string_literal: true

class AddUsableStorageBytesToZoektNodes < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :zoekt_nodes, :usable_storage_bytes, :bigint, null: false, default: 0, if_not_exists: true
    add_column :zoekt_nodes, :usable_storage_bytes_locked_until, :timestamptz, if_not_exists: true
  end
end
