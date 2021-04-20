# frozen_string_literal: true

class ChangeNamespaceSettingsDelayedProjectRemovalNull < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    change_column :namespace_settings, :delayed_project_removal, :boolean, null: true, default: nil
  end

  def down
    change_column_default :namespace_settings, :delayed_project_removal, false
    change_column_null :namespace_settings, :delayed_project_removal, false, false
  end
end
