# frozen_string_literal: true

class AddDefaultPreferredLanguageToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20221101032600_add_text_limit_to_default_preferred_language_on_application_settings.rb
    add_column :application_settings, :default_preferred_language, :text, default: 'en', null: false
    # rubocop:enable Migration/AddLimitToTextColumns
  end
end
