# frozen_string_literal: true

class AddUserTypeMigrationIndexes < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  BILLABLE_INDEX = 'index_users_for_active_billable_users_migration'
  LAST_ACTIVITY_INDEX = 'i_users_on_last_activity_for_active_human_service_migration'

  def up
    # Temporary indexes to migrate human user_type. See https://gitlab.com/gitlab-org/gitlab/-/issues/386474
    add_concurrent_index :users, :id, name: BILLABLE_INDEX,
      where: "state = 'active' AND ((user_type IS NULL OR user_type = 0) OR (user_type = ANY (ARRAY[6, 4, 13]))) " \
             "AND ((user_type IS NULL OR user_type = 0) OR (user_type = ANY (ARRAY[4, 5])))"
    add_concurrent_index :users, [:id, :last_activity_on], name: LAST_ACTIVITY_INDEX,
      where: "((state)::text = 'active'::text) AND ((user_type IS NULL OR user_type = 0) OR (user_type = 4))"
  end

  def down
    remove_concurrent_index_by_name :users, BILLABLE_INDEX
    remove_concurrent_index_by_name :users, LAST_ACTIVITY_INDEX
  end
end
