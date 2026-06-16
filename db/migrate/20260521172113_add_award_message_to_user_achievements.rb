# frozen_string_literal: true

class AddAwardMessageToUserAchievements < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_column :user_achievements, :award_message, :text, null: true, if_not_exists: true
    add_text_limit :user_achievements, :award_message, 200
  end

  def down
    remove_column :user_achievements, :award_message, if_exists: true
  end
end
