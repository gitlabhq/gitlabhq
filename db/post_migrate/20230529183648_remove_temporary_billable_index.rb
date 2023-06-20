# frozen_string_literal: true

class RemoveTemporaryBillableIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'migrate_index_users_for_active_billable_users'
  def up
    remove_concurrent_index_by_name :users, INDEX_NAME
  end

  def down
    add_concurrent_index :users, :id,
      name: INDEX_NAME,
      where: "((state)::text = 'active'::text) " \
             "AND (user_type IS NULL OR user_type = 0 OR user_type = ANY (ARRAY[0, 6, 4, 13])) " \
             "AND (user_type IS NULL OR user_type = 0 OR user_type = ANY (ARRAY[0, 4, 5]))"
  end
end
