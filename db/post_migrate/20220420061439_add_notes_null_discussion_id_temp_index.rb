# frozen_string_literal: true

class AddNotesNullDiscussionIdTempIndex < Gitlab::Database::Migration[2.0]
  # Temporary index to be removed in 15.0 https://gitlab.com/gitlab-org/gitlab/-/issues/357581
  INDEX_NAME = 'tmp_index_notes_on_id_where_discussion_id_is_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index :notes, :id, where: 'discussion_id IS NULL', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end
end
