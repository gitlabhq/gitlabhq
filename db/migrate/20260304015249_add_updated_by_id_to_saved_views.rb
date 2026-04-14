# frozen_string_literal: true

class AddUpdatedByIdToSavedViews < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.11'

  def up
    with_lock_retries do
      add_column :saved_views, :updated_by_id, :bigint
    end

    add_concurrent_foreign_key :saved_views, :users, column: :updated_by_id, on_delete: :nullify,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_column :saved_views, :updated_by_id
    end
  end
end
