# frozen_string_literal: true

class AddMergeRequestDiffsProjectIdForeignKey < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  def up
    add_concurrent_foreign_key :merge_request_diffs, :projects,
      column: :project_id, on_delete: :cascade, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_request_diffs, column: :project_id
    end
  end
end
