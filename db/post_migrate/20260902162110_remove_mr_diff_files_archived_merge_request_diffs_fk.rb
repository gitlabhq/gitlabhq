# frozen_string_literal: true

class RemoveMrDiffFilesArchivedMergeRequestDiffsFk < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  SOURCE_TABLE = :merge_request_diff_files_archived
  TARGET_TABLE = :merge_request_diffs
  FK_NAME      = 'fk_rails_501aa0a391'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE,
        TARGET_TABLE,
        name: FK_NAME,
        column: :merge_request_diff_id
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      SOURCE_TABLE,
      TARGET_TABLE,
      name: FK_NAME,
      column: :merge_request_diff_id,
      on_delete: :cascade
    )
  end
end
