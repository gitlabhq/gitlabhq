# frozen_string_literal: true

class AddTargetPlatformsToProjectSetting < Gitlab::Database::Migration[1.0]
  def change
    add_column :project_settings, :target_platforms, :string, array: true, default: [], null: false, if_not_exists: true
  end
end
