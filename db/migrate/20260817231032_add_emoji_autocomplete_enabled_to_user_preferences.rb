# frozen_string_literal: true

class AddEmojiAutocompleteEnabledToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :user_preferences, :emoji_autocomplete_enabled, :boolean, default: true, null: false
  end
end
