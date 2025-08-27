# frozen_string_literal: true

class DropSprintIdColumnIndexAndFkFromMergeRequests < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  TABLE_NAME = :merge_requests
  COLUMN_NAME = :sprint_id
  INDEX_NAME = :index_merge_requests_on_sprint_id
  FOREIGN_KEY_NAME = :fk_7e85395a64

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(TABLE_NAME, :sprints, name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end

    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
    remove_column(TABLE_NAME, COLUMN_NAME, if_exists: true)
  end

  def down
    with_lock_retries do
      add_column(TABLE_NAME, COLUMN_NAME, :bigint, if_not_exists: true)
    end

    add_concurrent_index(TABLE_NAME, COLUMN_NAME, name: INDEX_NAME)

    add_concurrent_foreign_key(TABLE_NAME, :sprints,
      name: FOREIGN_KEY_NAME, column: COLUMN_NAME,
      target_column: :id, on_delete: :nullify)
  end
end
