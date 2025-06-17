# frozen_string_literal: true

class AddWorkItemsDisplaySettingsToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :user_preferences, :work_items_display_settings, :jsonb, default: {}, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :user_preferences, :work_items_display_settings
    end
  end
end
