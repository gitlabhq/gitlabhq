# frozen_string_literal: true

class AddShardingKeyToSystemNoteMetadata < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Sharding key is an exception
    add_column :system_note_metadata, :namespace_id, :bigint
    add_column :system_note_metadata, :organization_id, :bigint
    # rubocop:enable Migration/PreventAddingColumns
  end
end
