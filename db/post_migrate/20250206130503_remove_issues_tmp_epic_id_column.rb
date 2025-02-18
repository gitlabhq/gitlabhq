# frozen_string_literal: true

class RemoveIssuesTmpEpicIdColumn < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  INDEX_NAME = "tmp_index_issues_on_tmp_epic_id"

  def up
    with_lock_retries do
      remove_column :issues, :tmp_epic_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column(:issues, :tmp_epic_id, :bigint, if_not_exists: true)
    end

    add_concurrent_index :issues, :tmp_epic_id, unique: true, name: INDEX_NAME
    add_concurrent_foreign_key :issues, :epics, column: :tmp_epic_id, on_delete: :cascade
  end
end
