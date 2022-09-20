# frozen_string_literal: true

class RemoveExperienceLevelColumn < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    remove_column :user_preferences, :experience_level
  end

  def down
    add_column :user_preferences, :experience_level, :integer, limit: 2
  end
end
