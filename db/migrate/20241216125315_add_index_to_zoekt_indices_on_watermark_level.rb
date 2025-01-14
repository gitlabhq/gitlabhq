# frozen_string_literal: true

class AddIndexToZoektIndicesOnWatermarkLevel < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_zoekt_indices_on_watermark_level_and_id'

  milestone '17.8'
  disable_ddl_transaction!

  def up
    add_concurrent_index :zoekt_indices, [:watermark_level, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :zoekt_indices, INDEX_NAME
  end
end
