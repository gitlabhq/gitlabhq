# frozen_string_literal: true

class RemoveTemporaryIndexFromSystemNoteMetadata < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_for_backfilling_resource_link_events'
  CONDITION = "action='relate_to_parent' OR action='unrelate_from_parent'"

  def up
    remove_concurrent_index_by_name :system_note_metadata, INDEX_NAME
  end

  def down
    add_concurrent_index :system_note_metadata, :id,
      where: CONDITION,
      name: INDEX_NAME
  end
end
