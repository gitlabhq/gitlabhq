# frozen_string_literal: true

class DropHomeOrganizationFromUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_user_preferences_on_home_organization_id'

  def up
    with_lock_retries do
      remove_column :user_preferences, :home_organization_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column :user_preferences, :home_organization_id, :bigint, if_not_exists: true
    end
    add_concurrent_index :user_preferences, :home_organization_id, name: INDEX_NAME
  end
end
