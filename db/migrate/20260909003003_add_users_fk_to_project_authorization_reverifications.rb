# frozen_string_literal: true

class AddUsersFkToProjectAuthorizationReverifications < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_authorization_reverifications, :users,
      column: :user_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :project_authorization_reverifications, column: :user_id
    end
  end
end
