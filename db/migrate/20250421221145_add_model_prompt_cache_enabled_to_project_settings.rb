# frozen_string_literal: true

class AddModelPromptCacheEnabledToProjectSettings < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def change
    add_column :project_settings, :model_prompt_cache_enabled, :boolean, default: nil, null: true
  end
end
