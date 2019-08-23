# frozen_string_literal: true

class AddNotificationEmailToNotificationSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :notification_settings, :notification_email, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
