# frozen_string_literal: true

class AddErrorNotificationSentToRemoteMirrors < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :remote_mirrors, :error_notification_sent, :boolean
  end
end
