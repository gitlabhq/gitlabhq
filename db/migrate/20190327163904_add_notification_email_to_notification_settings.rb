# frozen_string_literal: true

class AddNotificationEmailToNotificationSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :notification_settings, :notification_email, :string
  end
  # rubocop:enable Migration/PreventStrings
end
