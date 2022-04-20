# frozen_string_literal: true

class AddUserForeignKeyToDeployTokens < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :deploy_tokens, :users, column: :creator_id, on_delete: :nullify, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key :deploy_tokens, column: :creator_id
    end
  end
end
