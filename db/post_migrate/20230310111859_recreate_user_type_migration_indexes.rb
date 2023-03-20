# frozen_string_literal: true

class RecreateUserTypeMigrationIndexes < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INCORRECT_BILLABLE_INDEX = 'index_users_for_active_billable_users_migration'
  BILLABLE_INDEX = 'migrate_index_users_for_active_billable_users'

  def up
    # Temporary index to migrate human user_type. See https://gitlab.com/gitlab-org/gitlab/-/issues/386474
    add_concurrent_index :users, :id, name: BILLABLE_INDEX,
      where: "state = 'active' AND ((user_type IS NULL OR user_type = 0) OR (user_type = ANY (ARRAY[0, 6, 4, 13]))) " \
             "AND ((user_type IS NULL OR user_type = 0) OR (user_type = ANY (ARRAY[0, 4, 5])))"

    remove_concurrent_index_by_name :users, INCORRECT_BILLABLE_INDEX
  end

  def down
    add_concurrent_index :users, :id, name: INCORRECT_BILLABLE_INDEX,
      where: "state = 'active' AND ((user_type IS NULL OR user_type = 0) OR (user_type = ANY (ARRAY[6, 4, 13]))) " \
             "AND ((user_type IS NULL OR user_type = 0) OR (user_type = ANY (ARRAY[4, 5])))"
    remove_concurrent_index_by_name :users, BILLABLE_INDEX
  end
end
