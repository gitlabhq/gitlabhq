# frozen_string_literal: true

class RemoveUseLegacyWebIdeColumn < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def up
    remove_column :user_preferences, :use_legacy_web_ide
  end

  def down
    add_column :user_preferences, :use_legacy_web_ide, :boolean, default: false, null: false
  end
end
