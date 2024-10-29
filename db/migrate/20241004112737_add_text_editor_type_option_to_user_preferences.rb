# frozen_string_literal: true

class AddTextEditorTypeOptionToUserPreferences < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :user_preferences, :text_editor_type, :integer, default: 0, null: false, limit: 2
  end
end
