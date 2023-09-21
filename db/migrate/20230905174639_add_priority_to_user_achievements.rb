# frozen_string_literal: true

class AddPriorityToUserAchievements < Gitlab::Database::Migration[2.1]
  def change
    add_column :user_achievements, :priority, :int, null: true, default: nil
  end
end
