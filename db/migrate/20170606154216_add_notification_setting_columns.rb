class AddNotificationSettingColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  COLUMNS = [
    :new_note,
    :new_issue,
    :reopen_issue,
    :close_issue,
    :reassign_issue,
    :new_merge_request,
    :reopen_merge_request,
    :close_merge_request,
    :reassign_merge_request,
    :merge_merge_request,
    :failed_pipeline,
    :success_pipeline
  ]

  def change
    COLUMNS.each do |column|
      add_column(:notification_settings, column, :boolean)
    end
  end
end
