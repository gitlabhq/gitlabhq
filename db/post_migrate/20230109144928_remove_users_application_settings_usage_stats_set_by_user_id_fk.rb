# frozen_string_literal: true

class RemoveUsersApplicationSettingsUsageStatsSetByUserIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:application_settings, :users, name: "fk_964370041d")

    with_lock_retries do
      execute('LOCK users, application_settings IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:application_settings, :users, name: "fk_964370041d")
    end
  end

  def down
    add_concurrent_foreign_key(:application_settings, :users,
      name: "fk_964370041d", column: :usage_stats_set_by_user_id,
      target_column: :id, on_delete: :nullify)
  end
end
