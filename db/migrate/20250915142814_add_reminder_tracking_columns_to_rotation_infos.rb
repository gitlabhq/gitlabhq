# frozen_string_literal: true

class AddReminderTrackingColumnsToRotationInfos < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  INDEX_NAME = 'index_secret_rotation_infos_on_next_reminder_at'

  def up
    truncate_tables!('secret_rotation_infos')

    with_lock_retries do
      add_column :secret_rotation_infos, :next_reminder_at, :datetime_with_timezone, null: false, if_not_exists: true # rubocop:disable Rails/NotNullColumn -- no meaningful default
      add_column :secret_rotation_infos, :last_reminder_at, :datetime_with_timezone, null: true, if_not_exists: true
    end

    add_concurrent_index :secret_rotation_infos, :next_reminder_at, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :secret_rotation_infos, INDEX_NAME

    with_lock_retries do
      remove_column :secret_rotation_infos, :last_reminder_at, if_exists: true
      remove_column :secret_rotation_infos, :next_reminder_at, if_exists: true
    end
  end
end
