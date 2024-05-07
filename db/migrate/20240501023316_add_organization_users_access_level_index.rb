# frozen_string_literal: true

class AddOrganizationUsersAccessLevelIndex < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_organization_users_on_org_id_access_level_user_id'

  disable_ddl_transaction!

  milestone '17.0'

  def up
    add_concurrent_index :organization_users, [:organization_id, :access_level, :user_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :organization_users, INDEX_NAME
  end
end
