# frozen_string_literal: true

class AddOperationsScopesProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :operations_scopes, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :operations_scopes, column: :project_id
    end
  end
end
