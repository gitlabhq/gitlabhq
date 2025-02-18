# frozen_string_literal: true

class AddMergeRequestDiffDetailsProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_request_diff_details, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_request_diff_details, column: :project_id
    end
  end
end
