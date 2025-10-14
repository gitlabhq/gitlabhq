# frozen_string_literal: true

class AddShardingKeyToNoteDiffFiles < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Sharding key is an exception
    add_column :note_diff_files, :namespace_id, :bigint
    # rubocop:enable Migration/PreventAddingColumns
  end
end
