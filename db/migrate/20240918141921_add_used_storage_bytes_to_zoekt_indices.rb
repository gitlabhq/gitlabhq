# frozen_string_literal: true

class AddUsedStorageBytesToZoektIndices < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    add_column :zoekt_indices, :used_storage_bytes, :bigint, default: 0, null: false
  end

  def down
    remove_column :zoekt_indices, :used_storage_bytes
  end
end
