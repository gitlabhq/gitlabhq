# frozen_string_literal: true

class PrepareIndexToSystemNoteMetadataOnIdForRelateAndUnrelateActions < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'tmp_index_for_backfilling_resource_link_events'
  CLAUSE = "action='relate_to_parent' OR action='unrelate_from_parent'"

  disable_ddl_transaction!

  def up
    return if index_exists?(:system_note_metadata, :id, name: INDEX_NAME)

    # Temporary index to be removed https://gitlab.com/gitlab-org/gitlab/-/issues/408797
    # Sync index to be created in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119019
    prepare_async_index :system_note_metadata, :id, where: CLAUSE, name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :system_note_metadata, INDEX_NAME
  end
end
