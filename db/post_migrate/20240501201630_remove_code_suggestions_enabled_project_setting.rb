# frozen_string_literal: true

class RemoveCodeSuggestionsEnabledProjectSetting < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  def up
    remove_column :project_settings, :code_suggestions
  end

  def down
    add_column :project_settings, :code_suggestions, :boolean, default: true, null: false
  end
end
