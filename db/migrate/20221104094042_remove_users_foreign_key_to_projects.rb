# frozen_string_literal: true

class RemoveUsersForeignKeyToProjects < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :projects, column: :creator_id
    end
  end

  def down
    add_concurrent_foreign_key :projects, :users, column: :creator_id, on_delete: :nullify, validate: false
  end
end
