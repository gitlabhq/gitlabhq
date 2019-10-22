# frozen_string_literal: true

class AddNewReleaseToNotificationSettings < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :notification_settings, :new_release, :boolean
  end
end
