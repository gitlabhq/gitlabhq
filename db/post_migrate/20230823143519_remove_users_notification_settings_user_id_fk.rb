# frozen_string_literal: true

class RemoveUsersNotificationSettingsUserIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_0c95e91db7"

  def up
    return unless foreign_key_exists?(:notification_settings, :users, name: FOREIGN_KEY_NAME)

    with_lock_retries do
      remove_foreign_key_if_exists(:notification_settings, :users,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:notification_settings, :users,
      name: FOREIGN_KEY_NAME, column: :user_id,
      target_column: :id, on_delete: :cascade)
  end
end
