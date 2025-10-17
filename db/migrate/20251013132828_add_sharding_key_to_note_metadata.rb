# frozen_string_literal: true

class AddShardingKeyToNoteMetadata < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :note_metadata, :namespace_id, :bigint
  end
end
