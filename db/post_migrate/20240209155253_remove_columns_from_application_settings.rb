# frozen_string_literal: true

class RemoveColumnsFromApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  enable_lock_retries!

  def up
    remove_column :application_settings, :delayed_project_removal, if_exists: true
    remove_column :application_settings, :lock_delayed_project_removal, if_exists: true
    remove_column :application_settings, :delayed_group_deletion, if_exists: true
  end

  def down
    add_column :application_settings, :delayed_project_removal, :boolean, default: false,
      null: false, if_not_exists: true
    add_column :application_settings, :lock_delayed_project_removal, :boolean, default: false,
      null: false, if_not_exists: true
    add_column :application_settings, :delayed_group_deletion, :boolean, default: true, null: false, if_not_exists: true
  end
end
