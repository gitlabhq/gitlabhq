# frozen_string_literal: true

class AddDefaultSyntaxHighlightingThemeToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :default_syntax_highlighting_theme, :integer, default: 1, null: false
  end
end
