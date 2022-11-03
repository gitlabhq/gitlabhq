# frozen_string_literal: true

class AddTextLimitToDefaultPreferredLanguageOnApplicationSettings < Gitlab::Database::Migration[2.0]
  MAXIMUM_LIMIT = 32

  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :default_preferred_language, MAXIMUM_LIMIT
  end

  def down
    remove_text_limit :application_settings, :default_preferred_language
  end
end
