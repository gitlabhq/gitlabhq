# frozen_string_literal: true

class AddApprovalsProjectIdFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  def up
    add_concurrent_foreign_key :approvals, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :approvals, column: :project_id
    end
  end
end
