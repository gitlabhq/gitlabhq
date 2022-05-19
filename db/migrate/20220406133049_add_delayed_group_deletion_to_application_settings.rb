# frozen_string_literal: true

class AddDelayedGroupDeletionToApplicationSettings < Gitlab::Database::Migration[1.0]
  def up
    add_column :application_settings, :delayed_group_deletion, :boolean, default: true, null: false
  end

  def down
    remove_column :application_settings, :delayed_group_deletion
  end
end
