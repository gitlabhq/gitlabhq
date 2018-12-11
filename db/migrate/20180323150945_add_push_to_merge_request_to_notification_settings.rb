class AddPushToMergeRequestToNotificationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :notification_settings, :push_to_merge_request, :boolean
  end
end
