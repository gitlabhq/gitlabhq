# frozen_string_literal: true

class AddMarkdownSurroundSelectionToUserPreferences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :user_preferences, :markdown_surround_selection, :boolean, default: true, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :user_preferences, :markdown_surround_selection, :boolean
    end
  end
end
