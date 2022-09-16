# frozen_string_literal: true

class AddTmpIndexSystemNoteMetadataOnAttentionRequestActions < Gitlab::Database::Migration[2.0]
  INDEX_NAME = "tmp_index_system_note_metadata_on_attention_request_actions"

  disable_ddl_transaction!

  def up
    add_concurrent_index :system_note_metadata, [:id],
      where: "action IN ('attention_requested', 'attention_request_removed')",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :system_note_metadata, INDEX_NAME
  end
end
