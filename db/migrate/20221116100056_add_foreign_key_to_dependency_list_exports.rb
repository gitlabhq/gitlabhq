# frozen_string_literal: true

class AddForeignKeyToDependencyListExports < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :dependency_list_exports,
      :users,
      column: :user_id,
      on_delete: :nullify)
    add_concurrent_foreign_key(
      :dependency_list_exports,
      :projects,
      column: :project_id,
      on_delete: :cascade)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :dependency_list_exports, column: :user_id
    end
    with_lock_retries do
      remove_foreign_key_if_exists :dependency_list_exports, column: :project_id
    end
  end
end
