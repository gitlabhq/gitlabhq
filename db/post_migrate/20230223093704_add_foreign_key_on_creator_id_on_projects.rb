# frozen_string_literal: true

class AddForeignKeyOnCreatorIdOnProjects < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :projects, :users, column: :creator_id, on_delete: :nullify, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :projects, column: :creator_id
    end
  end
end
