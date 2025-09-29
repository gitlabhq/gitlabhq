# frozen_string_literal: true

class AddPolicyAdvancedEditorToUserPreference < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :user_preferences, :policy_advanced_editor, :boolean, default: false, null: false, if_not_exists: true
  end
end
