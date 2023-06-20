# frozen_string_literal: true

class RecreatedActivityIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_users_on_id_and_last_activity_on_for_active_human_service'

  def up
    remove_concurrent_index_by_name :users, INDEX_NAME

    add_concurrent_index :users, [:id, :last_activity_on],
      name: INDEX_NAME,
      where: "state = 'active' AND user_type IN (0, 4)"
  end

  def down
    remove_concurrent_index_by_name :users, INDEX_NAME

    add_concurrent_index :users, [:id, :last_activity_on],
      name: INDEX_NAME,
      where: "state = 'active' AND ((user_type IS NULL) OR (user_type = 4))"
  end
end
