# frozen_string_literal: true

class AddWatermarkLevelIndexToZoektIndices < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_zoekt_indices_on_watermark_level_reserved_storage_bytes'

  milestone '17.5'
  disable_ddl_transaction!

  def up
    add_concurrent_index :zoekt_indices,
      [:watermark_level, :id],
      where: "reserved_storage_bytes > 0",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:zoekt_indices, INDEX_NAME)
  end
end
