# frozen_string_literal: true

class CleanupTemporaryActivityIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'i_users_on_last_activity_for_active_human_service_migration'

  def up
    remove_concurrent_index_by_name :users, INDEX_NAME
  end

  def down
    add_concurrent_index :users, [:id, :last_activity_on],
      name: INDEX_NAME,
      where: "state = 'active' AND ((user_type IS NULL) OR (user_type = 0) OR (user_type = 4))"
  end
end
