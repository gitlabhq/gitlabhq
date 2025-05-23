# frozen_string_literal: true

class AddNotValidForeignKeyToMergeRequestDiffFiles < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :merge_request_diff_files,
      :projects,
      column: :project_id,
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    remove_foreign_key_if_exists :merge_request_diff_files, column: :project_id
  end
end
