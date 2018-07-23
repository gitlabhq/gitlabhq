# frozen_string_literal: true

class AddNewEpicToNotificationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :notification_settings, :new_epic, :boolean
  end
end
