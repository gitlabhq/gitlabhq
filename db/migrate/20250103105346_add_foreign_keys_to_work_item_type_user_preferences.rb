# frozen_string_literal: true

class AddForeignKeysToWorkItemTypeUserPreferences < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_type_user_preferences,
      :users,
      column: :user_id,
      on_delete: :cascade

    add_concurrent_index :work_item_type_user_preferences, :namespace_id
    add_concurrent_foreign_key :work_item_type_user_preferences,
      :namespaces,
      column: :namespace_id,
      on_delete: :cascade

    add_concurrent_index :work_item_type_user_preferences, :work_item_type_id
    add_concurrent_foreign_key :work_item_type_user_preferences,
      :work_item_types,
      target_column: :correct_id,
      column: :work_item_type_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_type_user_preferences, :users, column: :user_id
      remove_foreign_key_if_exists :work_item_type_user_preferences, :namespaces, column: :namespace_id
      remove_foreign_key_if_exists :work_item_type_user_preferences, :work_item_types, column: :work_item_type_id
    end
  end
end
