# frozen_string_literal: true

class AddViewDiffsFileByFileToUserPreferences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :user_preferences, :view_diffs_file_by_file, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :user_preferences, :view_diffs_file_by_file, :boolean
    end
  end
end
