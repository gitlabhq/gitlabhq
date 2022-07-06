# frozen_string_literal: true

class AddNamespaceBansUserIdForeignKey < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :namespace_bans, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :namespace_bans, column: :user_id
    end
  end
end
