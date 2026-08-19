# frozen_string_literal: true

class AddEmojiAutocompleteDisabledIndexToUserPreferences < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  INDEX_NAME = 'index_user_preferences_on_user_id_emoji_autocomplete_disabled'

  def up
    add_concurrent_index :user_preferences, :user_id,
      where: 'emoji_autocomplete_enabled = false', name: INDEX_NAME

    connection.execute('ANALYZE user_preferences')
  end

  def down
    remove_concurrent_index_by_name :user_preferences, INDEX_NAME
  end
end
