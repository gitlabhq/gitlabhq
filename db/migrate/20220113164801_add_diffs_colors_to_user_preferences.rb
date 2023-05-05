# frozen_string_literal: true

class AddDiffsColorsToUserPreferences < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220113164901_add_text_limit_to_user_preferences_diffs_colors.rb
  def change
    add_column :user_preferences, :diffs_deletion_color, :text
    add_column :user_preferences, :diffs_addition_color, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
