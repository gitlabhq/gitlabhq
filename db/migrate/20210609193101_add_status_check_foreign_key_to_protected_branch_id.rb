# frozen_string_literal: true

class AddStatusCheckForeignKeyToProtectedBranchId < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :external_status_checks_protected_branches, :protected_branches, column: :protected_branch_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :external_status_checks_protected_branches, column: :protected_branch_id
    end
  end
end
