# frozen_string_literal: true

class AddMarkdownSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :application_settings, :markdown_settings, :jsonb, default: {}, null: false
  end
end
