# frozen_string_literal: true

class AddNamespaceFkToUserSavedViews < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_foreign_key :user_saved_views, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_saved_views, column: :namespace_id
    end
  end
end
