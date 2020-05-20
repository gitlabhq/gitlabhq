# frozen_string_literal: true

class AddEmailRestrictionsToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  def up
    add_column(:application_settings, :email_restrictions_enabled, :boolean, default: false, null: false)
    add_column(:application_settings, :email_restrictions, :text, null: true)
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column(:application_settings, :email_restrictions_enabled)
    remove_column(:application_settings, :email_restrictions)
  end
end
