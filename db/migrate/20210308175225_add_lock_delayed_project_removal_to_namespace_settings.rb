# frozen_string_literal: true

class AddLockDelayedProjectRemovalToNamespaceSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :namespace_settings, :lock_delayed_project_removal, :boolean, default: false, null: false
  end
end
