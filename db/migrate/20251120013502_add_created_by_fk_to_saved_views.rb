# frozen_string_literal: true

class AddCreatedByFkToSavedViews < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_foreign_key :saved_views, :users, column: :created_by_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :saved_views, column: :created_by_id
    end
  end
end
