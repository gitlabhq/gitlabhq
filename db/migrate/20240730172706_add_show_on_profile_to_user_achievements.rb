# frozen_string_literal: true

class AddShowOnProfileToUserAchievements < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :user_achievements, :show_on_profile, :boolean, default: true, null: false
  end
end
