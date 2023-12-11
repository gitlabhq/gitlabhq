# frozen_string_literal: true

class DropIndexUsersOnIdAndLastActivity < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  TABLE_NAME = :users
  INDEX_NAME = :index_users_on_id_and_last_activity_on_for_active_human_service

  def up
    return unless should_run?

    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    return unless should_run?

    add_concurrent_index :users, [:id, :last_activity_on],
      name: INDEX_NAME,
      where: "state = 'active' AND user_type IN (0, 4)"
  end

  def should_run?
    Gitlab.com_except_jh?
  end
end
