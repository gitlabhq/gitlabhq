# frozen_string_literal: true

class AddZoektIndexOverprovisionedReadyHighWatermarkExceeded < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_zoekt_indices_on_id_conditional_watermark_level_state'
  milestone '17.7'
  disable_ddl_transaction!

  def up
    add_concurrent_index :zoekt_indices, :id,
      where: 'watermark_level = 10 AND state = 10 OR watermark_level = 60', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:zoekt_indices, INDEX_NAME)
  end
end
