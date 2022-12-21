# frozen_string_literal: true

class UserAchievementsForeignKeys < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :user_achievements, :users, column: :user_id, on_delete: :cascade
    add_concurrent_foreign_key :user_achievements, :users, column: :awarded_by_user_id, on_delete: :nullify
    add_concurrent_foreign_key :user_achievements, :users, column: :revoked_by_user_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_achievements, column: :user_id
      remove_foreign_key :user_achievements, column: :awarded_by_user_id
      remove_foreign_key :user_achievements, column: :revoked_by_user_id
    end
  end
end
