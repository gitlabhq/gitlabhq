# frozen_string_literal: true

class ChangeUserAchievementsShowOnProfileDefault < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    change_column_default :user_achievements, :show_on_profile, from: true, to: false
  end
end
