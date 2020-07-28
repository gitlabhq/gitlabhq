# frozen_string_literal: true

class AddMovedProjectToNotificationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :notification_settings, :moved_project, :boolean, default: true, null: false
  end
end
