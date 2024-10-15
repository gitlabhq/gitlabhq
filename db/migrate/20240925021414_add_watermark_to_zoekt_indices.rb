# frozen_string_literal: true

class AddWatermarkToZoektIndices < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    add_column :zoekt_indices, :watermark_level, :integer, null: false, limit: 2, default: 0
  end

  def down
    remove_column :zoekt_indices, :watermark_level
  end
end
