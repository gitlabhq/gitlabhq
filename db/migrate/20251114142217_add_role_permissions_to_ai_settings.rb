# frozen_string_literal: true

class AddRolePermissionsToAiSettings < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column :ai_settings, :minimum_access_level_execute, :integer, limit: 2, null: true
    add_column :ai_settings, :minimum_access_level_manage, :integer, limit: 2, null: true
    add_column :ai_settings, :minimum_access_level_enable_on_projects, :integer, limit: 2, null: true
  end
end
