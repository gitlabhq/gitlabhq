# frozen_string_literal: true

class AddTextLimitToUserPreferencesDiffsColors < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :user_preferences, :diffs_deletion_color, 7
    add_text_limit :user_preferences, :diffs_addition_color, 7
  end

  def down
    remove_text_limit :user_preferences, :diffs_addition_color
    remove_text_limit :user_preferences, :diffs_deletion_color
  end
end
