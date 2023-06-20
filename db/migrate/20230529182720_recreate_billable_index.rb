# frozen_string_literal: true

class RecreateBillableIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_users_for_active_billable_users"

  def up
    remove_concurrent_index_by_name :users, INDEX_NAME

    add_concurrent_index :users, :id, name: INDEX_NAME,
      where: "state = 'active' AND (user_type IN (0, 6, 4, 13)) AND (user_type IN (0, 4, 5))"
  end

  def down
    remove_concurrent_index_by_name :users, INDEX_NAME

    add_concurrent_index :users, :id, name: INDEX_NAME,
      where: "state = 'active' AND (user_type IS NULL OR user_type IN (6, 4, 13)) " \
             "AND (user_type IS NULL OR user_type IN (4, 5))"
  end
end
