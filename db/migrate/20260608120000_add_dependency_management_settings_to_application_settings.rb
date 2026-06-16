# frozen_string_literal: true

class AddDependencyManagementSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :application_settings, :dependency_management_settings, :jsonb, default: {}, null: false
  end
end
