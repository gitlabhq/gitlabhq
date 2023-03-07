# frozen_string_literal: true

class DropRevokableFromAchievements < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    remove_column :achievements, :revokeable, :boolean, default: false, null: false
  end
end
