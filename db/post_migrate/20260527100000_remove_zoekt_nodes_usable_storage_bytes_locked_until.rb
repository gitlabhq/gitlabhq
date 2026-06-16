# frozen_string_literal: true

class RemoveZoektNodesUsableStorageBytesLockedUntil < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    remove_column :zoekt_nodes, :usable_storage_bytes_locked_until
  end

  def down
    add_column :zoekt_nodes, :usable_storage_bytes_locked_until, :timestamptz
  end
end
