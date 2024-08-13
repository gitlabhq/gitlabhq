# frozen_string_literal: true

class AddReservedStorageBytesToZoektIndices < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :zoekt_indices, :reserved_storage_bytes, :bigint
  end
end
