# frozen_string_literal: true

class RemoveMrDiffFilesArchivedProjectsFk < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  SOURCE_TABLE = :merge_request_diff_files_archived
  TARGET_TABLE = :projects
  FK_NAME      = 'fk_0e3ba01603'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE,
        TARGET_TABLE,
        name: FK_NAME,
        column: :project_id
      )
    end
  end

  # This FK was NOT VALID in the original schema; restore it with validate: false.
  def down
    add_concurrent_foreign_key(
      SOURCE_TABLE,
      TARGET_TABLE,
      name: FK_NAME,
      column: :project_id,
      on_delete: :cascade,
      validate: false
    )
  end
end
