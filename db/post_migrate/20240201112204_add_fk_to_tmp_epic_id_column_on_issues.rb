# frozen_string_literal: true

class AddFkToTmpEpicIdColumnOnIssues < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :issues, :epics, column: :tmp_epic_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :issues, column: :tmp_epic_id
    end
  end
end
