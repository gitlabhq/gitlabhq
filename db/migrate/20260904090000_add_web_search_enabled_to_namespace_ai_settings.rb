# frozen_string_literal: true

class AddWebSearchEnabledToNamespaceAiSettings < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def up
    add_column :namespace_ai_settings, :web_search_enabled, :boolean, default: false, null: false
  end

  def down
    remove_column :namespace_ai_settings, :web_search_enabled
  end
end
