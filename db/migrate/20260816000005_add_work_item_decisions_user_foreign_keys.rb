# frozen_string_literal: true

class AddWorkItemDecisionsUserForeignKeys < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_decisions, :users,
      column: :author_id, on_delete: :nullify, reverse_lock_order: true
    add_concurrent_foreign_key :work_item_decisions, :users,
      column: :resolved_by_id, on_delete: :nullify, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_decisions, column: :author_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :work_item_decisions, column: :resolved_by_id
    end
  end
end
