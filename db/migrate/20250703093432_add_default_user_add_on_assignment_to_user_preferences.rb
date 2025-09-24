# frozen_string_literal: true

class AddDefaultUserAddOnAssignmentToUserPreferences < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'
  INDEX_NAME = 'add_default_user_assignment_to_user_preferences'

  def up
    with_lock_retries do
      add_column :user_preferences, :default_duo_add_on_assignment_id, :bigint, null: true, if_not_exists: true
    end

    add_concurrent_index :user_preferences, :default_duo_add_on_assignment_id, unique: true, name: INDEX_NAME
  end

  def down
    with_lock_retries do
      remove_column :user_preferences, :default_duo_add_on_assignment_id
    end
  end
end
