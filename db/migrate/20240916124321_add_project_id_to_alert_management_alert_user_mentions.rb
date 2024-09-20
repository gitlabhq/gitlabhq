# frozen_string_literal: true

class AddProjectIdToAlertManagementAlertUserMentions < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :alert_management_alert_user_mentions, :project_id, :bigint
  end
end
