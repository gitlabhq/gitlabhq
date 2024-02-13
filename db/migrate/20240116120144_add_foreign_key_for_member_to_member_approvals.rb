# frozen_string_literal: true

class AddForeignKeyForMemberToMemberApprovals < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  def up
    add_concurrent_foreign_key :member_approvals, :members, column: :member_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :member_approvals, column: :member_id
    end
  end
end
