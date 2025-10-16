# frozen_string_literal: true

class AddForeignKeyToProjectPushRules < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_push_rules, :projects,
      column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :project_push_rules, column: :project_id
    end
  end
end
