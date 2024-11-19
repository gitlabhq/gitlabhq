# frozen_string_literal: true

class RemoveCodeSuggestionsEnabledNamespaceSetting < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    remove_column :namespace_settings, :code_suggestions
  end

  def down
    add_column :namespace_settings, :code_suggestions, :boolean, default: true, null: false
  end
end
