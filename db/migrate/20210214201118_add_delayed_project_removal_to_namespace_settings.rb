# frozen_string_literal: true

class AddDelayedProjectRemovalToNamespaceSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :namespace_settings, :delayed_project_removal, :boolean, default: false, null: false
  end
end
