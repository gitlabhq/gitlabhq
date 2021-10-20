# frozen_string_literal: true

class AddSuggestPipelineEnabledToApplicationSettings < Gitlab::Database::Migration[1.0]
  def change
    add_column :application_settings, :suggest_pipeline_enabled, :boolean, default: true, null: false
  end
end
