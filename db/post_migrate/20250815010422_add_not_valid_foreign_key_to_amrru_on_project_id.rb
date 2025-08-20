# frozen_string_literal: true

class AddNotValidForeignKeyToAmrruOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_concurrent_foreign_key(
      :approval_merge_request_rules_users,
      :projects,
      column: :project_id,
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    remove_foreign_key_if_exists :approval_merge_request_rules_users, column: :project_id
  end
end
