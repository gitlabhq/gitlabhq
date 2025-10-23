# frozen_string_literal: true

class AddShardingKeyToDiffNotePositions < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :diff_note_positions, :namespace_id, :bigint
  end
end
