# frozen_string_literal: true

class AddMemberIdForeignKeyToMemberTasks < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :member_tasks, :members, column: :member_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :member_tasks, column: :member_id
    end
  end
end
